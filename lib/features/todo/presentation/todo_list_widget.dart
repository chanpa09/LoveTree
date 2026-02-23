import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/todo_model.dart';
import '../../../core/theme/app_theme.dart';
import '../data/todo_repository.dart';

class TodoListWidget extends ConsumerStatefulWidget {
  final String coupleId;
  final double? height;
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
  final _todoController = TextEditingController();
  List<TodoModel> _todos = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshTodos();
  }

  @override
  void dispose() {
    _todoController.dispose();
    super.dispose();
  }

  Future<void> _refreshTodos() async {
    final repo = ref.read(todoRepositoryProvider);
    final localTodos = await repo.getLocalTodos(widget.coupleId);
    if (mounted) {
      setState(() => _todos = localTodos);
    }

    // 백그라운드 동기화 후 화면만 조용히 갱신
    repo.syncTodos(widget.coupleId).then((_) async {
      final syncedTodos = await repo.getLocalTodos(widget.coupleId);
      if (mounted) {
        setState(() => _todos = syncedTodos);
      }
    }).catchError((_) {});
  }

  void _addTodo() async {
    final text = _todoController.text.trim()
        .replaceAll(RegExp(r'<[^>]*>'), ''); // HTML 태그 제거
    if (text.isEmpty || text.length > 100) return;

    _todoController.clear();

    final repo = ref.read(todoRepositoryProvider);
    await repo.addTodo(widget.coupleId, text);
    await _refreshTodos();
  }

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
    final cardWidth = (screenWidth * 0.38).clamp(140.0, 200.0);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 (showHeader가 true일 때만 전체 표시)
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

          // 투두 리스트
          SizedBox(
            height: listHeight,
            child: _todos.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.checklist_rounded,
                          size: 32,
                          color: AppTheme.textHint.withOpacity(0.3),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '오늘 할 일을 추가해보세요 ✍️',
                          style: TextStyle(
                            color: AppTheme.textHint,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _todos.length,
                    itemBuilder: (context, index) {
                      final todo = _todos[index];
                      return GestureDetector(
                        onLongPress: () => _showDeleteDialog(todo),
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
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // 할 일 추가 바텀시트
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
              decoration: InputDecoration(
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

  // 삭제 확인 다이얼로그
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
            child: Text('취소',
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
