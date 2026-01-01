import 'package:flutter/material.dart';
import '../data/todo.dart';
import 'todo_card.dart';

class PriorityView extends StatefulWidget {
  const PriorityView({
    super.key,
    required this.todos,
    required this.onEdit,
    required this.onUpdate,
  });

  final List<Todo> todos;
  final Function(Todo) onEdit;
  final VoidCallback onUpdate;

  @override
  State<PriorityView> createState() => _PriorityViewState();
}

class _PriorityViewState extends State<PriorityView> {
  @override
  Widget build(BuildContext context) {
    final groupedTodos = <Priority, List<Todo>>{};
    for (var todo in widget.todos) {
      groupedTodos.putIfAbsent(todo.priority, () => []).add(todo);
    }

    // Sort priorities: High -> Medium -> Low -> None
    final priorities = [
      Priority.high,
      Priority.medium,
      Priority.low,
      Priority.none,
    ];

    return ListView.builder(
      itemCount: priorities.length,
      itemBuilder: (context, index) {
        final priority = priorities[index];
        final todos = groupedTodos[priority] ?? [];
        todos.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });

        return DragTarget<Todo>(
          onWillAccept: (data) => data != null && data.priority != priority,
          onAccept: (data) {
            data.priority = priority; // Update priority
            widget.onUpdate();
          },
          builder: (context, candidateData, rejectedData) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    priority.displayName.toUpperCase(),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
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
