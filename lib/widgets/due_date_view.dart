import 'package:flutter/material.dart';
import '../data/todo.dart';
import 'todo_card.dart';

class DueDateView extends StatefulWidget {
  const DueDateView({
    super.key,
    required this.todos,
    required this.onEdit,
    required this.onUpdate,
  });

  final List<Todo> todos;
  final Function(Todo) onEdit;
  final VoidCallback onUpdate;

  @override
  State<DueDateView> createState() => _DueDateViewState();
}

class _DueDateViewState extends State<DueDateView> {
  @override
  Widget build(BuildContext context) {
    final sortedTodos = List<Todo>.from(widget.todos);
    sortedTodos.sort((a, b) {
      if (a.dueDate == null && b.dueDate == null) return 0;
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      return a.dueDate!.compareTo(b.dueDate!);
    });

    final overdue = <Todo>[];
    final today = <Todo>[];
    final tomorrow = <Todo>[];
    final later = <Todo>[];
    final noDate = <Todo>[];

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final tomorrowStart = todayStart.add(const Duration(days: 1));

    for (var todo in sortedTodos) {
      if (todo.dueDate == null) {
        noDate.add(todo);
      } else {
        final due = DateTime(
          todo.dueDate!.year,
          todo.dueDate!.month,
          todo.dueDate!.day,
        );
        if (due.isBefore(todayStart)) {
          overdue.add(todo);
        } else if (due.isAtSameMomentAs(todayStart)) {
          today.add(todo);
        } else if (due.isAtSameMomentAs(tomorrowStart)) {
          tomorrow.add(todo);
        } else {
          later.add(todo);
        }
      }
    }

    final sections = [
      if (overdue.isNotEmpty) MapEntry('期限切れ', overdue),
      if (today.isNotEmpty) MapEntry('今日', today),
      if (tomorrow.isNotEmpty) MapEntry('明日', tomorrow),
      if (later.isNotEmpty) MapEntry('以降', later),
      if (noDate.isNotEmpty) MapEntry('期限なし', noDate),
    ];

    return ListView.builder(
      itemCount: sections.length,
      itemBuilder: (context, index) {
        final section = sections[index];
        final title = section.key;
        final todos = section.value;

        return DragTarget<Todo>(
          onWillAccept: (data) => data != null,
          onAccept: (data) {
            DateTime? newDate;
            final now = DateTime.now();
            if (title == '今日') {
              newDate = now;
            } else if (title == '明日') {
              newDate = now.add(const Duration(days: 1));
            } else if (title == '期限切れ') {
              newDate = now.subtract(const Duration(days: 1));
            } else if (title == '以降') {
              newDate = now.add(const Duration(days: 7));
            } else {
              newDate = null;
            }
            data.dueDate = newDate;
            widget.onUpdate();
          },
          builder: (context, candidateData, rejectedData) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    title.toUpperCase(),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: title == '期限切れ'
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                if (candidateData.isNotEmpty)
                  Container(
                    height: 50,
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Drop here',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ...todos.map(
                  (todo) => Draggable<Todo>(
                    data: todo,
                    feedback: SizedBox(
                      width: MediaQuery.of(context).size.width - 32,
                      child: TodoCard(
                        todo: todo,
                        onEdit: () {},
                        onCheckboxChanged: (value) {},
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.3,
                      child: TodoCard(
                        todo: todo,
                        onEdit: () {},
                        onCheckboxChanged: (value) {},
                      ),
                    ),
                    child: TodoCard(
                      todo: todo,
                      onEdit: () => widget.onEdit(todo),
                      onCheckboxChanged: (value) {
                        todo.isDone = value!;
                        widget.onUpdate();
                      },
                    ),
                  ),
                ),
                const Divider(),
              ],
            );
          },
        );
      },
    );
  }
}
