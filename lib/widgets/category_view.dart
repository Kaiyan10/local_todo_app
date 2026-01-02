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
  });

  final List<Todo> todos;
  final Function(Todo) onEdit;
  final VoidCallback onUpdate;
  final Function(Todo, bool?) onToggle;
  final Function(Todo)? onTodoChanged;
  final Function(Todo, Todo)? onPromote;

  @override
  State<CategoryView> createState() => _CategoryViewState();
}

class _CategoryViewState extends State<CategoryView> {
  @override
  Widget build(BuildContext context) {
    // カテゴリごとに Todo をグループ化
    final groupedTodos = <GtdCategory, List<Todo>>{};
    for (var todo in widget.todos) {
      groupedTodos.putIfAbsent(todo.category, () => []).add(todo);
    }

    // 全てのカテゴリを表示（ドラッグ＆ドロップ用）
    final categories = GtdCategory.values;

    return ListView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final todos = groupedTodos[category] ?? [];
        todos.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });

        return DragTarget<Todo>(
          onWillAccept: (data) => data != null && data.category != category,
          onAccept: (data) {
            data.category = category;
            widget.onUpdate();
          },
          builder: (context, candidateData, rejectedData) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  color: Colors.transparent,
                  child: ExpansionTile(
                    title: Text(
                      SettingsService().getCategoryName(category),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
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
                if (category == GtdCategory.waitingFor) ...[
                  ..._buildGroupedByDelegatee(todos, context),
                ] else ...[
                  ...todos.map(
                    (todo) => Draggable<Todo>(
                      data: todo,
                      feedback: Material(
                        elevation: 4.0,
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.transparent,
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width - 32,
                          child: TodoCard(
                            todo: todo,
                            onEdit: () {},
                            onCheckboxChanged: (value) {},
                          ),
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
                          widget.onToggle(todo, value);
                        },
                        onTodoChanged: widget.onTodoChanged,
                        onPromote: widget.onPromote,
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
                widget.onToggle(todo, value);
              },
              onTodoChanged: widget.onTodoChanged,
              onPromote: widget.onPromote,
            ),
          ),
        ),
      );
    }
    return widgets;
  }
}
