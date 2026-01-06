import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/todo.dart';
import '../providers/todo_providers.dart';
import 'todo_card.dart';
import 'package:intl/intl.dart';

class ContextView extends ConsumerStatefulWidget {
  const ContextView({
    super.key,
    required this.todos,
    required this.onEdit,
  });

  final List<Todo> todos;
  final Function(Todo) onEdit;

  @override
  ConsumerState<ContextView> createState() => _ContextViewState();
}

class _ContextViewState extends ConsumerState<ContextView> {
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

  Future<void> _toggleTodo(Todo todo, bool? value) async {
    final notifier = ref.read(todoListProvider.notifier);
    final nextDate = await notifier.toggleTodo(todo, value);
    
    if (nextDate != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '次のタスクを作成しました: ${DateFormat.yMd().format(nextDate)}',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _updateTodo(Todo todo) async {
    await ref.read(todoListProvider.notifier).updateTodo(todo);
  }

  Future<void> _deleteTodo(Todo todo) async {
    if (todo.id != null) {
      await ref.read(todoListProvider.notifier).deleteTodo(todo.id!);
    }
  }

  Future<void> _promoteSubTask(Todo parent, Todo subTask) async {
    await ref.read(todoListProvider.notifier).promoteSubTask(parent, subTask);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('"${subTask.title}" をタスクに昇格しました')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get contexts from SettingsService via Provider
    final availableContexts = ref.watch(settingsServiceProvider).contexts;
    final categories = ref.watch(settingsServiceProvider).categories;

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
              // If NO context selected, hide empty categories
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
                      onCheckboxChanged: (val) => _toggleTodo(todo, val),
                      onTodoChanged: _updateTodo,
                      onPromote: _promoteSubTask,
                      onDelete: _deleteTodo,
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
