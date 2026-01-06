import 'package:flutter/material.dart';
import '../data/todo.dart';
import '../data/settings_service.dart';
import 'todo_card.dart';

class CategoryView extends StatefulWidget {
  const CategoryView({
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
  State<CategoryView> createState() => _CategoryViewState();
}

class _CategoryViewState extends State<CategoryView> {
  final ScrollController _scrollController = ScrollController();
  late Map<String, List<Todo>> _groupedTodos;

  @override
  void initState() {
    super.initState();
    _groupTodos();
  }

  @override
  void didUpdateWidget(CategoryView oldWidget) {
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
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 全てのカテゴリを表示（ドラッグ＆ドロップ用）
    final categories = SettingsService().categories;

    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 120),
        controller: _scrollController,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final todos = _groupedTodos[category.id] ?? [];
  
          return DragTarget<Todo>(
            onWillAccept: (data) => data != null && data.categoryId != category.id,
            onAccept: (data) {
              if (widget.onTodoChanged != null) {
                final updatedTodo = data.copyWith(categoryId: category.id);
                widget.onTodoChanged!(updatedTodo);
              }
            },
            builder: (context, candidateData, rejectedData) {
              final isHovering = candidateData.isNotEmpty;
              
              return ExpansionTile(
                initiallyExpanded: true,
                collapsedBackgroundColor: isHovering 
                    ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
                    : null,
                backgroundColor: isHovering 
                    ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1)
                    : null,
                title: Text(
                  category.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                children: [
                  if (isHovering)
                    Container(
                      height: 50,
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Drop to move to ${category.name}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (category.id == 'waitingFor') ...[
                    ..._buildGroupedByDelegatee(todos, context),
                  ] else ...[
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
                  ],
                  const Divider(),
                ],
              );
            },
          );
        },
      ),
    );
  }

  List<Widget> _buildGroupedByDelegatee(
    List<Todo> todos,
    BuildContext context,
  ) {
    final Map<String?, List<Todo>> grouped = {};
    for (var todo in todos) {
      grouped.putIfAbsent(todo.delegatee, () => []).add(todo);
    }

    // 担当者が設定されているものを先に、未設定（nullまたは空）を後に表示するようにソート
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        if (a == null || a.isEmpty) return 1;
        if (b == null || b.isEmpty) return -1;
        return a.compareTo(b);
      });

    final List<Widget> widgets = [];
    for (var key in sortedKeys) {
      final label = (key == null || key.isEmpty) ? '担当者未設定' : key;
      final groupTodos = grouped[key]!;

      widgets.add(
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );

      widgets.addAll(
        groupTodos.map(
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
      );
    }
    return widgets;
  }
}
