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
  State<ContextView> createState() => _ContextViewState();
}

class _ContextViewState extends State<ContextView> {
  String? _selectedContext;
  late Map<String, List<Todo>> _groupedTodos;

  @override
  void initState() {
    super.initState();
    _groupTodos();
  }

  @override
  void didUpdateWidget(ContextView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.todos != oldWidget.todos) {
      _groupTodos();
    }
  }

  void _groupTodos() {
    _groupedTodos = {};
    for (var todo in widget.todos) {
      _groupedTodos.putIfAbsent(todo.categoryId, () => []).add(todo);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get contexts from SettingsService
    final availableContexts = SettingsService().contexts;
    final categories = SettingsService().categories;

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

        // Grouped Todo List (Categories)
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 120),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              var todos = _groupedTodos[category.id] ?? [];
              
              // Filter todos for this category AND the selected context
              // Note: _groupedTodos is already grouped by category.
              // So we just need to filter by context.
              if (_selectedContext != null) {
                todos = todos.where((t) => t.tags.contains(_selectedContext)).toList();
              }

              // If filtering by context, hide empty categories
              if (todos.isEmpty && _selectedContext != null) {
                return const SizedBox.shrink();
              }
              // If NO context selected, hide empty categories?
              // Existing logic said "hide empty categories to avoid clutter"
              if (todos.isEmpty) {
                 return const SizedBox.shrink();
              }

              return ExpansionTile(
                initiallyExpanded: true,
                title: Text(
                  category.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                children: todos.map((todo) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: TodoCard(
                      todo: todo,
                      onEdit: () => widget.onEdit(todo),
                      onCheckboxChanged: (val) => widget.onToggle(todo, val),
                      onTodoChanged: widget.onTodoChanged,
                      onPromote: widget.onPromote,
                      onDelete: widget.onDelete,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }
}
