import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/todo_model.dart';
import '../../../core/theme/app_theme.dart';
import '../data/todo_repository.dart';

/// 커플이 함께 관리하는 공동 할 일 목록을 보여주는 위젯입니다.
/// 가로 스크롤 형태의 리스트를 제공하며, 상태 토글, 추가, 삭제 기능을 포함합니다.
class TodoListWidget extends ConsumerStatefulWidget {
  /// 현재 사용자가 속한 커플의 고유 ID
  final String coupleId;
  /// 위젯의 전체 높이 (지정하지 않으면 기본값 사용)
  final double? height;
  /// 헤더(제목 및 추가 버튼) 표시 여부
  final bool showHeader;
  const TodoListWidget({
    super.key,
    required this.coupleId,
    this.height,
    this.showHeader = true,
  });

  @override
  ConsumerState<TodoListWidget> createState() => _TodoListWidgetState();
}

class _TodoListWidgetState extends ConsumerState<TodoListWidget> {
  /// 할 일 입력을 위한 컨트롤러
  final _todoController = TextEditingController();
  /// 현재 화면에 표시되는 필터링된 할 일 리스트
  List<TodoModel> _todos = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 위젯 초기화 시 데이터를 불러옵니다.
    _refreshTodos();
  }

  @override
  void dispose() {
    _todoController.dispose();
    super.dispose();
  }

  /// 로컬 데이터를 즉시 노출하고, 서버와 비동기 동기화를 수행하여 데이터를 갱신합니다.
  Future<void> _refreshTodos() async {
    final repo = ref.read(todoRepositoryProvider);
    
    // 1. 로컬 캐시/DB 데이터를 먼저 화면에 뿌려줌 (빠른 응답성)
    final localTodos = await repo.getLocalTodos(widget.coupleId);
    if (mounted) {
      setState(() => _todos = localTodos);
    }

    // 2. 서버와 백그라운드 동기화 진행 (사용자 모르게 최신화)
    repo.syncTodos(widget.coupleId).then((_) async {
      final syncedTodos = await repo.getLocalTodos(widget.coupleId);
      if (mounted) {
        setState(() => _todos = syncedTodos);
      }
    }).catchError((_) {
      // 동기화 실패 시에도 로컬 데이터는 유지되므로 별도의 에러 처리 생략
    });
  }

  /// 새로운 할 일을 추가합니다.
  void _addTodo() async {
    final text = _todoController.text.trim()
        .replaceAll(RegExp(r'<[^>]*>'), ''); // 보안: 불필요한 HTML 태그 제거
    
    // 빈 값이거나 너무 긴 경우 무시
    if (text.isEmpty || text.length > 100) return;

    _todoController.clear();

    final repo = ref.read(todoRepositoryProvider);
    // [Step 1] 리포지토리에 추가 요청 (낙관적 업데이트 실행됨)
    await repo.addTodo(widget.coupleId, text);
    // [Step 2] 로컬 상태 갱신
    await _refreshTodos();
  }

  /// 특정 할 일을 삭제합니다.
  void _deleteTodo(TodoModel todo) async {
    final repo = ref.read(todoRepositoryProvider);
    await repo.deleteTodo(todo);
    await _refreshTodos();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final listHeight = widget.height ?? 115.0;
    // 화면 너비에 따라 카드 너비를 유동적으로 계산
    final cardWidth = (screenWidth * 0.38).clamp(140.0, 200.0);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 헤더 영역 (제목 & 빠른 추가 아이콘) ──
          if (widget.showHeader)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 18,
                        decoration: BoxDecoration(
                          color: AppTheme.mint,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '부부 공동 할 일',
                        style: TextStyle(
                          fontSize: 17,
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
                      onTap: _showAddTodoSheet,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusS),
                        ),
                        child: const Icon(Icons.add_rounded,
                            color: AppTheme.primary, size: 22),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            // showHeader가 false일 때도 추가 버튼은 우상단에 작게 노출
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppTheme.radiusS),
                    onTap: _showAddTodoSheet,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusS),
                      ),
                      child: const Icon(Icons.add_rounded,
                          color: AppTheme.primary, size: 20),
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 14),

          // ── 할 일 목록 영역 (가로 스크롤) ──
          SizedBox(
            height: listHeight,
            child: _todos.isEmpty
                ? _buildEmptyView()
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _todos.length,
                    itemBuilder: (context, index) {
                      final todo = _todos[index];
                      return _buildTodoCard(todo, cardWidth, isDark);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// 할 일이 없을 때 보여주는 빈 화면 위젯
  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.checklist_rounded,
            size: 32,
            color: AppTheme.textHint.withOpacity(0.3),
          ),
          const SizedBox(height: 8),
          const Text(
            '오늘 할 일을 추가해보세요 ✍️',
            style: TextStyle(
              color: AppTheme.textHint,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// 개별 할 일 카드 위젯 빌더
  Widget _buildTodoCard(TodoModel todo, double cardWidth, bool isDark) {
    return GestureDetector(
      onLongPress: () => _showDeleteDialog(todo), // 꾹 눌러서 삭제
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: cardWidth,
        margin: const EdgeInsets.only(right: 12, bottom: 4),
        decoration: BoxDecoration(
          color: todo.isDone
              ? (isDark
                  ? AppTheme.darkSurfaceVariant
                  : const Color(0xFFF8F9FA))
              : (isDark
                  ? AppTheme.darkCard
                  : Colors.white),
          borderRadius:
              BorderRadius.circular(AppTheme.radiusM),
          boxShadow: todo.isDone
              ? null
              : (isDark ? null : AppTheme.cardShadow),
          border: todo.isDone
              ? Border.all(
                  color: isDark
                      ? Colors.white10
                      : Colors.grey.shade200,
                  width: 1.5)
              : Border.all(
                  color: isDark
                      ? Colors.white10
                      : AppTheme.primary.withOpacity(0.1),
                  width: 1.5),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius:
                BorderRadius.circular(AppTheme.radiusM),
            onTap: () async {
              // 상태 토글: 체크박스 클릭과 동일한 효과
              await ref
                  .read(todoRepositoryProvider)
                  .toggleTodo(todo);
              _refreshTodos();
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    todo.task,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      decoration: todo.isDone
                          ? TextDecoration.lineThrough
                          : null,
                      decorationColor: AppTheme.textHint,
                      color: todo.isDone
                          ? AppTheme.textHint
                          : (isDark
                              ? AppTheme.darkTextPrimary
                              : AppTheme.textPrimary),
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      height: 1.3,
                    ),
                  ),
                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.end,
                    children: [
                      // 체크 상태 변화 시 부드러운 스케일 애니메이션 적용
                      AnimatedSwitcher(
                        duration: const Duration(
                            milliseconds: 300),
                        transitionBuilder:
                            (child, anim) {
                          return ScaleTransition(
                              scale: anim, child: child);
                        },
                        child: Icon(
                          todo.isDone
                              ? Icons
                                  .check_circle_rounded
                              : Icons.circle_outlined,
                          key: ValueKey(todo.isDone),
                          color: todo.isDone
                              ? AppTheme.mint
                              : AppTheme.accent,
                          size: 26,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 할 일을 새로 작성하기 위한 바텀시트를 노출합니다.
  void _showAddTodoSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkCard : Colors.white,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 28,
          right: 28,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 드래그 핸들
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [AppTheme.mint, Color(0xFF6DD5A0)],
                  ).createShader(bounds),
                  child: const Icon(Icons.add_task_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 10),
                Text(
                  '할 일 추가',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppTheme.darkTextPrimary
                        : AppTheme.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _todoController,
              decoration: const InputDecoration(
                hintText: '예: 기저귀 구매, 관리비 납부',
                hintStyle: TextStyle(color: AppTheme.textHint),
                prefixIcon: Icon(Icons.edit_rounded,
                    color: AppTheme.mint, size: 20),
              ),
              autofocus: true,
              onSubmitted: (_) {
                _addTodo();
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusL),
                gradient: const LinearGradient(
                  colors: [AppTheme.mint, Color(0xFF6DD5A0)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.mint.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  _addTodo();
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
                    Text('추가하기'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 할 일 삭제 여부를 확인하는 다이얼로그를 보여줍니다.
  void _showDeleteDialog(TodoModel todo) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        title: const Text('할 일 삭제'),
        content: Text('"${todo.task}"을(를) 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소',
                style: TextStyle(color: AppTheme.textHint)),
          ),
          TextButton(
            onPressed: () {
              _deleteTodo(todo);
              Navigator.pop(context);
            },
            child: const Text('삭제',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
