import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/models/event_model.dart';
import '../../../core/theme/app_theme.dart';
import '../data/calendar_repository.dart';
import 'widgets/add_event_sheet.dart';
import '../../todo/presentation/todo_list_widget.dart';
import 'event_detail_screen.dart';
import '../../../core/widgets/ad_banner_widget.dart';

String _formatKoreanDate(DateTime date) {
  const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
  final wd = weekdays[date.weekday - 1];
  return '${date.month}월 ${date.day}일 ($wd)';
}

/// 앱의 메인 기능인 캘린더 화면을 담당하는 위젯입니다.
/// TableCalendar를 기반으로 일정 표시, 스마트 마커(라벨), 투두 리스트 통합, 동기화 기능을 수행합니다.
class CalendarScreen extends ConsumerStatefulWidget {
  /// 현재 사용자가 속한 커플의 고유 ID
  final String coupleId;
  const CalendarScreen({super.key, required this.coupleId});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen>
    with TickerProviderStateMixin {
  /// 달력 표시 형식 (Month, Two Weeks, Week)
  CalendarFormat _calendarFormat = CalendarFormat.month;
  /// 현재 캘린더가 포커스하고 있는 날짜
  DateTime _focusedDay = DateTime.now();
  /// 사용자가 마우스나 터치로 선택한 날짜
  DateTime? _selectedDay;
  /// 전체 캐시된 일정 리스트
  List<EventModel> _allEvents = [];
  /// Firestore와 동기화 중인지 여부
  bool _isSyncing = false;
  /// 하단 투두 패널이 확장되었는지 여부
  bool _todoExpanded = false;

  /// 플로팅 액션 버튼(FAB) 애니메이션 컨트롤러
  late AnimationController _fabController;
  late Animation<double> _fabScale;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;

    // 일정 추가 FAB이 튕기듯 나타나는 애니메이션 설정
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fabScale = CurvedAnimation(
      parent: _fabController,
      curve: Curves.elasticOut,
    );
    _fabController.forward();

    // 초기 일정 데이터 로드 및 동기화 시작
    _refreshEvents();
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  /// 로컬 데이터를 먼저 보여주고, Firestore와 동기화한 뒤 다시 화면을 갱신합니다.
  Future<void> _refreshEvents() async {
    final repo = ref.read(calendarRepositoryProvider);
    
    // 1. 로컬 DB(SQLite/인메모리) 우선 노출
    final localEvents = await repo.getLocalEvents(widget.coupleId);
    if (mounted) setState(() => _allEvents = localEvents);

    // 2. 서버와 증분 동기화 수행
    setState(() => _isSyncing = true);
    await repo.syncEvents(widget.coupleId);
    
    // 3. 동기화 완료 후 최종 데이터로 갱신
    final syncedEvents = await repo.getLocalEvents(widget.coupleId);
    if (mounted) {
      setState(() {
        _allEvents = syncedEvents;
        _isSyncing = false;
      });
    }
  }

  /// 특정 날짜에 해당하는 일정들만 필터링하여 가져옵니다.
  List<EventModel> _getEventsForDay(DateTime day) {
    return _allEvents.where((e) => isSameDay(e.date, day)).toList();
  }

  /// 캘린더 포맷에 따라 셀당 최대 표시할 라벨(텍스트 마커) 수를 정의합니다.
  int get _maxLabels {
    switch (_calendarFormat) {
      case CalendarFormat.month:
        return 3;
      case CalendarFormat.twoWeeks:
        return 6;
      case CalendarFormat.week:
        return 12;
    }
  }

  /// 화면 높이와 캘린더 포맷에 맞추어 셀의 고정 높이를 계산합니다.
  double get _rowHeight {
    final screenHeight = MediaQuery.of(context).size.height;
    switch (_calendarFormat) {
      case CalendarFormat.month:
        return (screenHeight * 0.085).clamp(65.0, 90.0);
      case CalendarFormat.twoWeeks:
        return (screenHeight * 0.12).clamp(95.0, 140.0);
      case CalendarFormat.week:
        return (screenHeight * 0.22).clamp(150.0, 250.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPad = (screenWidth * 0.03).clamp(12.0, 24.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('우리의 달력'),
        actions: [
          // 동기화 상태 표시기 또는 수동 새로고침 버튼
          if (_isSyncing)
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primary.withOpacity(0.6),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.sync_rounded),
              onPressed: _refreshEvents,
              tooltip: '동기화',
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? AppTheme.darkBackgroundGradient
              : AppTheme.backgroundGradient,
        ),
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshEvents,
                color: AppTheme.primary,
                child: ListView(
                  children: [
                    // [1] 캘린더 영역 (TableCalendar)
                    Container(
                      margin: EdgeInsets.fromLTRB(
                          horizontalPad, 8, horizontalPad, 0),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkCard : Colors.white,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusL),
                        boxShadow: isDark ? null : AppTheme.cardShadow,
                      ),
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusL),
                        child: TableCalendar(
                          firstDay: DateTime.utc(2020, 1, 1),
                          lastDay: DateTime.utc(2030, 12, 31),
                          focusedDay: _focusedDay,
                          calendarFormat: _calendarFormat,
                          rowHeight: _rowHeight,
                          selectedDayPredicate: (day) =>
                              isSameDay(_selectedDay, day),
                          onDaySelected: (selectedDay, focusedDay) {
                            setState(() {
                              _selectedDay = selectedDay;
                              _focusedDay = focusedDay;
                            });
                          },
                          onFormatChanged: (format) {
                            setState(() => _calendarFormat = format);
                          },
                          eventLoader: _getEventsForDay,
                          calendarBuilders: CalendarBuilders(
                            // 셀 내부의 커스텀 일정 라벨 빌더
                            markerBuilder: (context, date, events) {
                              if (events.isEmpty) return null;
                              final typed = events.cast<EventModel>();
                              return _buildSmartMarkers(typed, isDark);
                            },
                          ),
                          headerStyle: HeaderStyle(
                            formatButtonVisible: true,
                            titleCentered: true,
                            formatButtonDecoration: BoxDecoration(
                              border: Border.all(
                                  color: AppTheme.primary, width: 1.5),
                              borderRadius: BorderRadius.circular(
                                  AppTheme.radiusS),
                            ),
                            formatButtonTextStyle: const TextStyle(
                              color: AppTheme.primary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            titleTextStyle: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppTheme.darkTextPrimary
                                  : AppTheme.textPrimary,
                            ),
                            leftChevronIcon: const Icon(
                                Icons.chevron_left_rounded,
                                color: AppTheme.primary,
                                size: 28),
                            rightChevronIcon: const Icon(
                                Icons.chevron_right_rounded,
                                color: AppTheme.primary,
                                size: 28),
                          ),
                          calendarStyle: CalendarStyle(
                            outsideDaysVisible: false,
                            cellMargin: const EdgeInsets.all(2),
                            cellPadding: const EdgeInsets.only(top: 2),
                            cellAlignment: Alignment.topCenter,
                            // 기본 마커는 표시하지 않음 (markerBuilder에서 직접 그림)
                            markerSize: 0,
                            markersMaxCount: 0,
                            todayDecoration: BoxDecoration(
                              color:
                                  AppTheme.primaryLight.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(
                                  AppTheme.radiusS),
                            ),
                            selectedDecoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(
                                  AppTheme.radiusS),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppTheme.primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            defaultDecoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                  AppTheme.radiusS),
                            ),
                            weekendDecoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                  AppTheme.radiusS),
                            ),
                            todayTextStyle: TextStyle(
                              color: isDark
                                  ? AppTheme.darkTextPrimary
                                  : AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                            selectedTextStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            weekendTextStyle: TextStyle(
                              color: AppTheme.primary.withOpacity(0.8),
                            ),
                          ),
                          daysOfWeekStyle: DaysOfWeekStyle(
                            weekdayStyle: TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            weekendStyle: TextStyle(
                              color: AppTheme.primary.withOpacity(0.7),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // [2] 선택 날짜 상세 스케줄 리스트
                    if (_selectedDay != null) ...[
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                            horizontalPad + 4, 16, horizontalPad + 4, 8),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 20,
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _formatKoreanDate(_selectedDay!),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? AppTheme.darkTextPrimary
                                    : AppTheme.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            if (_getEventsForDay(_selectedDay!).isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      AppTheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.radiusS),
                                ),
                                child: Text(
                                  '${_getEventsForDay(_selectedDay!).length}개',
                                  style: const TextStyle(
                                    color: AppTheme.primary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      ..._buildEventCards(isDark, horizontalPad),
                    ],

                    // [3] 하단 접이식 투두 리스트 (부부 공동 할 일)
                    Container(
                      margin: EdgeInsets.fromLTRB(
                          horizontalPad, 16, horizontalPad, 16),
                      decoration: BoxDecoration(
                        color: isDark ? AppTheme.darkCard : Colors.white,
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusL),
                        boxShadow: isDark ? null : AppTheme.cardShadow,
                      ),
                      child: Theme(
                        data: Theme.of(context)
                            .copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          initiallyExpanded: _todoExpanded,
                          onExpansionChanged: (v) =>
                              setState(() => _todoExpanded = v),
                          tilePadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          leading: Container(
                            width: 4,
                            height: 18,
                            decoration: BoxDecoration(
                              color: AppTheme.mint,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          title: Text(
                            '부부 공동 할 일',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppTheme.darkTextPrimary
                                  : AppTheme.textPrimary,
                            ),
                          ),
                          children: [
                            TodoListWidget(
                              coupleId: widget.coupleId,
                              height: 130, // 제한된 높이 내에서 스크롤 가능
                              showHeader: false, // ExpansionTile 제목을 사용하므로 헤더 숨김
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 80), // 하단 FAB이 콘텐츠를 가리지 않도록 여백
                  ],
                ),
              ),
            ),
            // 하단 광고 배너
            const AdBannerWidget(),
          ],
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabScale,
        child: FloatingActionButton.extended(
          onPressed: () => _showAddEventSheet(),
          icon: const Icon(Icons.add_rounded),
          label: const Text('일정 추가'),
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          elevation: 6,
        ),
      ),
    );
  }

  /// 캘린더 날짜 셀 내부에 스마트하게 일정 라벨을 배치합니다.
  /// 일정 개수가 정해진 한도를 넘어서면 '+N' 형태로 표시합니다.
  Widget _buildSmartMarkers(List<EventModel> events, bool isDark) {
    final maxLabels = _maxLabels;
    final visibleCount = events.length <= maxLabels
        ? events.length
        : maxLabels;
    final remaining = events.length - visibleCount;

    return Positioned(
      bottom: 2,
      left: 2,
      right: 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < visibleCount; i++)
            _buildEventLabel(events[i]),
          if (remaining > 0)
            Padding(
              padding: const EdgeInsets.only(top: 1),
              child: Text(
                '+$remaining',
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 개별 일정에 대한 칩 형태의 라벨 위젯을 생성합니다.
  Widget _buildEventLabel(EventModel event) {
    final color =
        AppTheme.eventColors[event.colorIndex % AppTheme.eventColors.length];
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.85),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        event.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: Colors.white,
          height: 1.2,
        ),
      ),
    );
  }

  /// 선택된 날짜 아래에 표시될 상세 일정 카드 리스트를 생성합니다.
  List<Widget> _buildEventCards(bool isDark, double horizontalPad) {
    final events = _getEventsForDay(_selectedDay!);

    // 일정이 없는 경우 빈 안내 화면 리스트 반환
    if (events.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.event_note_rounded,
                    size: 48,
                    color: AppTheme.textHint.withOpacity(0.3)),
                const SizedBox(height: 12),
                const Text(
                  '이 날엔 일정이 없어요',
                  style: TextStyle(
                      color: AppTheme.textHint,
                      fontSize: 15,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ];
    }

    // 일정이 있는 경우 각 일정을 카드로 렌더링 (순차 페이드인 애니메이션 적용)
    return events.asMap().entries.map((entry) {
      final index = entry.key;
      final event = entry.value;
      final color = AppTheme
          .eventColors[event.colorIndex % AppTheme.eventColors.length];

      return TweenAnimationBuilder<double>(
        key: ValueKey(event.id),
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 250 + (index * 80)),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, 16 * (1 - value)),
              child: child,
            ),
          );
        },
        child: Container(
          margin: EdgeInsets.symmetric(
              horizontal: horizontalPad, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            boxShadow: isDark ? null : AppTheme.cardShadow,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppTheme.radiusM),
              onTap: () {
                // 클릭 시 일정 상세 화면으로 이동
                Navigator.push(
                  context,
                  AppTheme.fadeSlideRoute(
                      EventDetailScreen(event: event)),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusS),
                      ),
                      child: Icon(Icons.event_rounded,
                          color: color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: isDark
                                  ? AppTheme.darkTextPrimary
                                  : AppTheme.textPrimary,
                            ),
                          ),
                          if (event.description?.isNotEmpty ==
                              true) ...[
                            const SizedBox(height: 3),
                            Text(
                              event.description!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isDark
                                    ? AppTheme.darkTextSecondary
                                    : AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: AppTheme.textHint.withOpacity(0.5)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  /// 하단 모달 시트를 통해 일정 추가 화면을 띄웁니다.
  void _showAddEventSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // 키보드 노출 시 시트 밀려남 방지
      backgroundColor: Colors.transparent,
      builder: (context) {
        return AddEventSheet(
          selectedDay: _selectedDay!,
          coupleId: widget.coupleId,
          onSave: (event) async {
            final repo = ref.read(calendarRepositoryProvider);
            await repo.addEvent(event);
            _refreshEvents(); // 저장 후 리스트 즉시 갱신
          },
        );
      },
    );
  }
}
