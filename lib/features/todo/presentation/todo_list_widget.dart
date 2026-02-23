import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/todo_model.dart';
import '../data/todo_repository.dart';

class TodoListWidget extends ConsumerStatefulWidget {
  final String coupleId;
  const TodoListWidget({super.key, required this.coupleId});

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

  Future<void> _refreshTodos() async {
    final repo = ref.read(todoRepositoryProvider);
    final localTodos = await repo.getLocalTodos(widget.coupleId);
    setState(() => _todos = localTodos);

    await repo.syncTodos(widget.coupleId);
    final syncedTodos = await repo.getLocalTodos(widget.coupleId);
    if (mounted) {
      setState(() => _todos = syncedTodos);
    }
  }

  void _addTodo() async {
    if (_todoController.text.isEmpty) return;
    setState(() => _isLoading = true);
    final repo = ref.read(todoRepositoryProvider);
    await repo.addTodo(widget.coupleId, _todoController.text);
    _todoController.clear();
    await _refreshTodos();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '부부 공동 할 일',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF4A4A4A)),
                ),
                GestureDetector(
                  onTap: _showAddTodoDialog,
                  child: const Icon(Icons.add_circle, color: Color(0xFFFF85A1), size: 28),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: _todos.isEmpty
                ? Center(
                    child: Text(
                      '오늘 할 일을 추가해보세요 ✍️',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                    ),
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _todos.length,
                    itemBuilder: (context, index) {
                      final todo = _todos[index];
                      return Container(
                        width: 160,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: todo.isDone ? Colors.grey.shade100 : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: todo.isDone
                              ? null
                              : [
                                  BoxShadow(
                                    color: Colors.pink.withOpacity(0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                          border: todo.isDone ? null : Border.all(color: const Color(0xFFFFE5EC), width: 1),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () async {
                            await ref.read(todoRepositoryProvider).toggleTodo(todo);
                            _refreshTodos();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  todo.task,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    decoration: todo.isDone ? TextDecoration.lineThrough : null,
                                    color: todo.isDone ? Colors.grey : const Color(0xFF4A4A4A),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.bottomRight,
                                  child: Icon(
                                    todo.isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                                    color: todo.isDone ? Colors.green.shade300 : const Color(0xFFFFC2D1),
                                    size: 22,
                                  ),
                                ),
                              ],
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

  void _showAddTodoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('할 일 추가'),
        content: TextField(
          controller: _todoController,
          decoration: const InputDecoration(hintText: '예: 기저귀 구매, 관리비 납부'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('취소')),
          TextButton(onPressed: () {
            _addTodo();
            Navigator.pop(context);
          }, child: const Text('추가')),
        ],
      ),
    );
  }
}
