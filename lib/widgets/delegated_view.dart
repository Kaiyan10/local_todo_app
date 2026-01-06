import 'package:flutter/material.dart';
import '../data/todo.dart';
import 'todo_card.dart';

class DelegatedView extends StatefulWidget {
  const DelegatedView({
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
  State<DelegatedView> createState() => _DelegatedViewState();
}

class _DelegatedViewState extends State<DelegatedView> {
  late List<Todo> _delegatedTodos;
  late Map<String, List<Todo>> _groupedTodos;
  late List<String> _sortedKeys;

  @override
  void initState() {
    super.initState();
    _groupTodos();
  }

  @override
  void didUpdateWidget(DelegatedView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.todos != oldWidget.todos) {
      _groupTodos();
    }
  }

  void _groupTodos() {
    // 1. Filter for Waiting For tasks
    _delegatedTodos = widget.todos
        .where((t) => t.categoryId == 'waitingFor' && !t.isDone)
        .toList();

    // 2. Group by delegatee
    _groupedTodos = {};
    for (var todo in _delegatedTodos) {
      final name = todo.delegatee?.isNotEmpty == true
          ? todo.delegatee!
          : '担当者なし';
      if (!_groupedTodos.containsKey(name)) {
        _groupedTodos[name] = [];
      }
      _groupedTodos[name]!.add(todo);
    }

    _sortedKeys = _groupedTodos.keys.toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    if (_delegatedTodos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              '誰かに依頼しているタスクはありません',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 120),
      itemCount: _sortedKeys.length,
      itemBuilder: (context, index) {
        final delegatee = _sortedKeys[index];
        final todos = _groupedTodos[delegatee]!;

        return DragTarget<Todo>(
          onWillAccept: (data) => data != null, // Accept any todo
          onAccept: (data) {
            if (widget.onTodoChanged != null) {
              // Assign to this delegatee
              final isUnassigned = delegatee == '担当者なし';
              final updatedTodo = data.copyWith(
                delegatee: isUnassigned ? null : delegatee,
                resetDelegatee: isUnassigned,
                categoryId: 'waitingFor', // Implicitly ensure it's in Waiting For
              );
              widget.onTodoChanged!(updatedTodo);
            }
          },
          builder: (context, candidateData, rejectedData) {
            final isHovering = candidateData.isNotEmpty;
            return Card(
              // Use Card for visual grouping
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 0,
              color: isHovering 
                  ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                  : Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isHovering
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).dividerColor.withOpacity(0.1),
                  width: isHovering ? 2 : 1,
                ),
              ),
              child: ExpansionTile(
                initiallyExpanded: true,
                shape: Border.all(color: Colors.transparent),
                leading: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    delegatee.isNotEmpty ? delegatee[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  delegatee,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('${todos.length}'),
                ),
                children: todos
                    .map(
                      (todo) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0, left: 16.0, right: 16.0),
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
                                onCheckboxChanged: (val) => widget.onToggle(todo, val),
                                onTodoChanged: widget.onTodoChanged,
                                onPromote: widget.onPromote,
                                onDelete: widget.onDelete,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            );
          },
        );
      },
    );
  }
}
