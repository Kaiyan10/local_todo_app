import 'package:flutter/material.dart';
import '../data/todo.dart';
import 'todo_card.dart';

class PriorityView extends StatefulWidget {
  const PriorityView({
    super.key,
    required this.todos,
    required this.onEdit,
    required this.onUpdate,
    required this.onToggle,
    this.onTodoChanged,
    this.onPromote,
    this.onDelete,
  });

  final List<Todo> todos;
  final Function(Todo) onEdit;
  final VoidCallback onUpdate;
  final Function(Todo, bool?) onToggle;
  final Function(Todo)? onTodoChanged;
  final Function(Todo, Todo)? onPromote;
  final Function(Todo)? onDelete;

  @override
  State<PriorityView> createState() => _PriorityViewState();
}

class _PriorityViewState extends State<PriorityView> {
  late Map<Priority, List<Todo>> _groupedTodos;

  @override
  void initState() {
    super.initState();
    _groupTodos();
  }

  @override
  void didUpdateWidget(PriorityView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.todos != oldWidget.todos) {
      _groupTodos();
    }
  }

  void _groupTodos() {
    _groupedTodos = {};
    for (var todo in widget.todos) {
      _groupedTodos.putIfAbsent(todo.priority, () => []).add(todo);
    }
     // Pre-sort
    for (var list in _groupedTodos.values) {
      list.sort((a, b) {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
        return a.dueDate!.compareTo(b.dueDate!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sort priorities: High -> Medium -> Low -> None
    final priorities = [
      Priority.high,
      Priority.medium,
      Priority.low,
      Priority.none,
    ];

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 120),
      itemCount: priorities.length,
      itemBuilder: (context, index) {
        final priority = priorities[index];
        final todos = _groupedTodos[priority] ?? [];

        return DragTarget<Todo>(
          onWillAccept: (data) => data != null && data.priority != priority,
          onAccept: (data) {
            if (widget.onTodoChanged != null) {
              final updatedTodo = data.copyWith(priority: priority);
              widget.onTodoChanged!(updatedTodo);
            }
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
                  (todo) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Draggable<Todo>(
                          data: todo,
                          feedback: Material(
                            elevation: 4.0,
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.transparent,
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width - 64,
                              child: TodoCard(
                                todo: todo,
                                onEdit: () {},
                                onCheckboxChanged: (value) {},
                              ),
                            ),
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.3,
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: const Icon(Icons.drag_indicator, color: Colors.grey),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: const Icon(Icons.drag_indicator, color: Colors.grey),
                          ),
                        ),
                        Expanded(
                          child: TodoCard(
                            todo: todo,
                            onEdit: () => widget.onEdit(todo),
                            onCheckboxChanged: (value) {
                              widget.onToggle(todo, value);
                            },
                            onTodoChanged: widget.onTodoChanged,
                            onPromote: widget.onPromote,
                            onDelete: widget.onDelete,
                          ),
                        ),
                      ],
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
