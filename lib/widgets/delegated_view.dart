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
  });

  final List<Todo> todos;
  final Function(Todo) onEdit;
  final VoidCallback onUpdate;
  final Function(Todo, bool?) onToggle;
  final Function(Todo)? onTodoChanged;
  final Function(Todo, Todo)? onPromote;

  @override
  State<DelegatedView> createState() => _DelegatedViewState();
}

class _DelegatedViewState extends State<DelegatedView> {
  @override
  Widget build(BuildContext context) {
    // 1. Filter for Waiting For tasks
    final delegatedTodos = widget.todos
        .where((t) => t.category == GtdCategory.waitingFor && !t.isDone)
        .toList();

    if (delegatedTodos.isEmpty) {
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

    // 2. Group by delegatee
    final Map<String, List<Todo>> groupedTodos = {};
    for (var todo in delegatedTodos) {
      final name = todo.delegatee?.isNotEmpty == true
          ? todo.delegatee!
          : '担当者なし';
      if (!groupedTodos.containsKey(name)) {
        groupedTodos[name] = [];
      }
      groupedTodos[name]!.add(todo);
    }

    final sortedKeys = groupedTodos.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: sortedKeys.length,
      itemBuilder: (context, index) {
        final delegatee = sortedKeys[index];
        final todos = groupedTodos[delegatee]!;

        return Card(
          // Use Card for visual grouping
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 0,
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context).dividerColor.withOpacity(0.1),
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
                  (todo) => TodoCard(
                    todo: todo,
                    onEdit: () => widget.onEdit(todo),
                    onCheckboxChanged: (val) => widget.onToggle(todo, val),
                    onTodoChanged: widget.onTodoChanged,
                    onPromote: widget.onPromote,
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}
