import 'package:flutter/material.dart';
import '../data/todo.dart';
import '../widgets/todo_card.dart';

class TodayDueView extends StatelessWidget {
  const TodayDueView({
    super.key,
    required this.todos,
    required this.onEdit,
    required this.onUpdate,
  });

  final List<Todo> todos;
  final Function(Todo) onEdit;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    // filter todos due today
    final todayTodos = todos.where((todo) {
      if (todo.dueDate == null) return false;
      final due = DateTime(
        todo.dueDate!.year,
        todo.dueDate!.month,
        todo.dueDate!.day,
      );
      return due.isAtSameMomentAs(todayStart);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('今日の予定'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: todayTodos.isEmpty
          ? Center(
              child: Text(
                '今日の予定はありません',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            )
          : ListView.builder(
              itemCount: todayTodos.length,
              itemBuilder: (context, index) {
                final todo = todayTodos[index];
                return TodoCard(
                  todo: todo,
                  onEdit: () => onEdit(todo),
                  onCheckboxChanged: (value) {
                    todo.isDone = value!;
                    onUpdate();
                  },
                );
              },
            ),
    );
  }
}
