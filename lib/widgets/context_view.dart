import 'package:flutter/material.dart';
import '../data/todo.dart';
import '../data/settings_service.dart';
import 'todo_card.dart';

class ContextView extends StatefulWidget {
  const ContextView({
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
  State<ContextView> createState() => _ContextViewState();
}

class _ContextViewState extends State<ContextView> {
  String? _selectedContext;

  @override
  Widget build(BuildContext context) {
    // Get contexts from SettingsService + any used in actual todos to be safe
    final availableContexts = SettingsService().contexts;

    // Determine displayed todos
    final displayTodos = _selectedContext == null
        ? widget.todos
        : widget.todos.where((t) => t.tags.contains(_selectedContext)).toList();

    return Column(
      children: [
        // Horizontal Filter Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: availableContexts.map((ctx) {
              final isSelected = _selectedContext == ctx;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: FilterChip(
                  label: Text(ctx),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedContext = ctx;
                      } else {
                        // Deselect if tapping the same one
                        _selectedContext = null;
                      }
                    });
                  },
                ),
              );
            }).toList(),
          ),
        ),

        // Todo List
        Expanded(
          child: displayTodos.isEmpty
              ? Center(
                  child: Text(
                    _selectedContext != null
                        ? '$_selectedContext のタスクはありません'
                        : 'タスクがありません',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                )
              : ListView.builder(
                  itemCount: displayTodos.length,
                  itemBuilder: (context, index) {
                    final todo = displayTodos[index];
                    return TodoCard(
                      todo: todo,
                      onEdit: () => widget.onEdit(todo),
                      onCheckboxChanged: (val) => widget.onToggle(todo, val),
                      onTodoChanged: widget.onTodoChanged,
                    );
                  },
                ),
        ),
      ],
    );
  }
}
