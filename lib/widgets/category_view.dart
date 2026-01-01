import 'package:flutter/material.dart';
import '../data/todo.dart';
import 'todo_card.dart';

class CategoryView extends StatefulWidget {
  const CategoryView({
    super.key,
    required this.todos,
    required this.onEdit,
    required this.onUpdate,
  });

  final List<Todo> todos;
  final Function(Todo) onEdit;
  final VoidCallback onUpdate;

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
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    category.displayName.toUpperCase(),
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
