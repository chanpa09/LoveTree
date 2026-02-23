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

class CalendarScreen extends ConsumerStatefulWidget {
  final String coupleId;
  const CalendarScreen({super.key, required this.coupleId});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen>
    with TickerProviderStateMixin {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<EventModel> _allEvents = [];
  bool _isSyncing = false;
  bool _todoExpanded = false;

  late AnimationController _fabController;
  late Animation<double> _fabScale;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;

    _fabController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fabScale = CurvedAnimation(
      parent: _fabController,
      curve: Curves.elasticOut,
    );
    _fabController.forward();

    _refreshEvents();
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  Future<void> _refreshEvents() async {
    final repo = ref.read(calendarRepositoryProvider);
    final localEvents = await repo.getLocalEvents(widget.coupleId);
    if (mounted) setState(() => _allEvents = localEvents);

    setState(() => _isSyncing = true);
    await repo.syncEvents(widget.coupleId);
    final syncedEvents = await repo.getLocalEvents(widget.coupleId);
    if (mounted) {
      setState(() {
        _allEvents = syncedEvents;
        _isSyncing = false;
      });
    }
  }

  List<EventModel> _getEventsForDay(DateTime day) {
    return _allEvents.where((e) => isSameDay(e.date, day)).toList();
  }

  // 포맷별 최대 라벨 수
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

  // 포맷별 rowHeight
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
                    // ═══════════════════════════════════
                    // 1. 캘린더 (메인)
                    // ═══════════════════════════════════
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
                            // 기본 마커 비활성화 (커스텀 사용)
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

                    // ═══════════════════════════════════
                    // 2. 선택 날짜 스케줄 (날짜 클릭 시 표시)
                    // ═══════════════════════════════════
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

                    // ═══════════════════════════════════
                    // 3. 부부 공동 할 일 (접이식, 맨 아래)
                    // ═══════════════════════════════════
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
                              height: 130,
                              showHeader: false,
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 80), // FAB 공간
                  ],
                ),
              ),
            ),
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

  // ── 스마트 마커: 포맷별 maxLabels 적용 ──
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
                style: TextStyle(
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

  Widget _buildEventLabel(EventModel event) {
    final color =
        AppTheme.eventColors[event.colorIndex % AppTheme.eventColors.length];
    // 진한 배경 + 흰색 텍스트로 어디서든 잘 보이도록
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

  // ── 이벤트 카드 리스트 (빈 상태 포함) ──
  List<Widget> _buildEventCards(bool isDark, double horizontalPad) {
    final events = _getEventsForDay(_selectedDay!);

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
                Text(
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

  void _showAddEventSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return AddEventSheet(
          selectedDay: _selectedDay!,
          coupleId: widget.coupleId,
          onSave: (event) async {
            final repo = ref.read(calendarRepositoryProvider);
            await repo.addEvent(event);
            _refreshEvents();
          },
        );
      },
    );
  }
}
