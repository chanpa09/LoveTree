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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '공동 할 일',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.pinkAccent),
                onPressed: () => _showAddTodoDialog(),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 100,
          child: _todos.isEmpty
              ? const Center(child: Text('오늘 할 일이 없습니다.'))
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _todos.length,
                  itemBuilder: (context, index) {
                    final todo = _todos[index];
                    return Card(
                      color: todo.isDone ? Colors.grey.shade200 : Colors.white,
                      child: InkWell(
                        onTap: () async {
                          await ref.read(todoRepositoryProvider).toggleTodo(todo);
                          _refreshTodos();
                        },
                        child: Container(
                          width: 140,
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                todo.task,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  decoration: todo.isDone ? TextDecoration.lineThrough : null,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Icon(
                                todo.isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                                color: todo.isDone ? Colors.green : Colors.grey,
                                size: 18,
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
