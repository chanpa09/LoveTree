import 'package:flutter/material.dart';
import '../../../../core/models/event_model.dart';
import '../../../../core/theme/app_theme.dart';

/// 새로운 일정을 추가하기 위한 하단 모달 시트 위젯입니다.
/// 제목, 설명, 포인트 색상을 입력받으며 부드러운 진입 애니메이션을 포함합니다.
class AddEventSheet extends StatefulWidget {
  /// 일정에 할당될 날짜
  final DateTime selectedDay;
  /// 현재 커플의 고유 ID
  final String coupleId;
  /// 작성이 완료되었을 때 호출될 콜백 함수
  final Function(EventModel) onSave;

  const AddEventSheet({
    super.key,
    required this.selectedDay,
    required this.coupleId,
    required this.onSave,
  });

  @override
  State<AddEventSheet> createState() => _AddEventSheetState();
}

class _AddEventSheetState extends State<AddEventSheet>
    with SingleTickerProviderStateMixin {
  /// 일정 제목 컨트롤러
  final _titleController = TextEditingController();
  /// 일정 상세 설명 컨트롤러
  final _descController = TextEditingController();
  /// 선택된 포인트 색상의 인덱스 (AppTheme.eventColors 기반)
  int _selectedColorIndex = 0;

  // ── 애니메이션 설정 ──
  /// 모달이 밑에서 위로 부드럽게 올라오는 애니메이션 컨트롤러
  late AnimationController _animController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.1),
        end: Offset.zero,
      ).animate(_slideAnimation),
      child: FadeTransition(
        opacity: _slideAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkCard : Colors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          padding: EdgeInsets.only(
            // 키보드가 올라올 때 입력창이 가려지지 않도록 viewInsets.bottom 추가
            bottom: MediaQuery.of(context).viewInsets.bottom + 30,
            left: 28,
            right: 28,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 상단 드래그 핸들 (UI 데코레이션) ──
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── 헤더 영역 (제목 및 닫기 버튼) ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            AppTheme.primaryGradient.createShader(bounds),
                        child: const Icon(Icons.add_circle,
                            color: Colors.white, size: 28),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '새로운 일정',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppTheme.radiusS),
                      onTap: () => Navigator.pop(context),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(Icons.close_rounded,
                            color: AppTheme.textHint),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ── 제목 입력 필드 ──
              TextField(
                controller: _titleController,
                maxLength: 50,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.textPrimary,
                ),
                decoration: InputDecoration(
                  labelText: '어떤 일정인가요?',
                  labelStyle: TextStyle(color: AppTheme.textHint, fontSize: 14),
                  hintText: '예: 우리의 첫 캠핑, 맛집 탐방 등',
                  hintStyle: TextStyle(
                      color: AppTheme.textHint.withOpacity(0.5),
                      fontWeight: FontWeight.normal),
                  prefixIcon: Icon(Icons.edit_rounded,
                      color: AppTheme.primary, size: 20),
                  counterStyle: TextStyle(color: AppTheme.textHint, fontSize: 11),
                ),
                autofocus: true, // 시트가 열리자마자 키보드 활성화
              ),
              const SizedBox(height: 18),

              // ── 상세 설명 입력 필드 (선택 사항) ──
              TextField(
                controller: _descController,
                maxLength: 500,
                maxLines: 3,
                minLines: 1,
                style: TextStyle(
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.textPrimary,
                ),
                decoration: InputDecoration(
                  labelText: '상세를 남겨주세요 (선택)',
                  labelStyle: TextStyle(color: AppTheme.textHint, fontSize: 14),
                  prefixIcon: Icon(Icons.notes_rounded,
                      color: AppTheme.textHint, size: 20),
                  counterStyle: TextStyle(color: AppTheme.textHint, fontSize: 11),
                ),
              ),
              const SizedBox(height: 28),

              // ── 포인트 색상 선택 영역 ──
              Text(
                '포인트 색상',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppTheme.darkTextPrimary
                      : AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 52,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: AppTheme.eventColors.length,
                  itemBuilder: (context, index) {
                    final isSelected = _selectedColorIndex == index;
                    return GestureDetector(
                      onTap: () =>
                          setState(() => _selectedColorIndex = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.only(right: 12),
                        width: isSelected ? 48 : 40,
                        height: isSelected ? 48 : 40,
                        decoration: BoxDecoration(
                          color: AppTheme.eventColors[index],
                          shape: BoxShape.circle,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppTheme.eventColors[index]
                                        .withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                          border: isSelected
                              ? Border.all(
                                  color: Colors.white,
                                  width: 3)
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check_rounded,
                                color: Colors.white, size: 22)
                            : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),

              // ── 저장 및 반영 버튼 ──
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusL),
                  gradient: AppTheme.primaryGradient,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primary.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    // 데이터 정제: 양끝 공백 제거 및 보안을 위한 HTML 태그 제거
                    final title = _titleController.text.trim()
                        .replaceAll(RegExp(r'<[^>]*>'), '');
                    final desc = _descController.text.trim()
                        .replaceAll(RegExp(r'<[^>]*>'), '');

                    if (title.isEmpty) return;

                    final event = EventModel(
                      id: '', // 리포지토리에서 Firestore ID를 할당할 예정
                      coupleId: widget.coupleId,
                      title: title,
                      description: desc.isEmpty ? null : desc,
                      date: widget.selectedDay,
                      colorIndex: _selectedColorIndex,
                      updatedAt: DateTime.now(),
                    );
                    
                    // 넘겨받은 콜백 실행 후 시트 닫기
                    widget.onSave(event);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    elevation: 0,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('반영하기'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
