import 'package:flutter/material.dart';
import '../data/todo.dart';
import '../data/settings_service.dart';
import '../widgets/category_view.dart';
import '../widgets/priority_view.dart';
import '../widgets/due_date_view.dart';
import '../widgets/context_view.dart';
import '../widgets/quick_add_input.dart';
import '../widgets/delegated_view.dart';

enum TodoViewMode { category, priority, context, delegated, dueDate }

class TodoView extends StatefulWidget {
  const TodoView({
    super.key,
    required this.todos,
    required this.onUpdate,
    required this.onEdit,
    required this.onToggle,
    required this.onQuickAdd,
    this.onTodoChanged,
    this.onPromote,
  });

  final List<Todo> todos;
  final VoidCallback onUpdate;
  final Function(Todo) onEdit;
  final Function(Todo, bool?) onToggle;
  final Function(String) onQuickAdd;
  final Function(Todo)? onTodoChanged;
  final Function(Todo, Todo)? onPromote;

  @override
  State<TodoView> createState() => _TodoViewState();
}

class _TodoViewState extends State<TodoView> {
  TodoViewMode _viewMode = TodoViewMode.category;
  bool _showDone = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: SegmentedButton<TodoViewMode>(
            showSelectedIcon: false,
            expandedInsets: EdgeInsets.all(5.0),
            style: ButtonStyle(),
            segments: [
              ButtonSegment(
                value: TodoViewMode.category,
                label: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('カテゴリ'),
                ),
              ),
              ButtonSegment(
                value: TodoViewMode.priority,
                label: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('優先度'),
                ),
              ),
              ButtonSegment(
                value: TodoViewMode.delegated,
                label: Padding(padding: EdgeInsets.all(8.0), child: Text('委任')),
              ),
              ButtonSegment(
                value: TodoViewMode.context,
                label: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('@Context'),
                ),
              ),
              ButtonSegment(
                value: TodoViewMode.dueDate,
                label: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('期限日'),
                ),
              ),
            ],
            selected: {_viewMode},
            onSelectionChanged: (Set<TodoViewMode> newSelection) {
              setState(() {
                _viewMode = newSelection.first;
              });
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(child: QuickAddInput(onAdd: widget.onQuickAdd)),
            SizedBox(width: 10),
            const Text('対応済も表示'),
            Switch(
              value: _showDone,
              onChanged: (value) {
                setState(() {
                  _showDone = value;
                });
              },
            ),
          ],
        ),

        const SizedBox(height: 8),

        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    final displayTodos = _showDone
        ? widget.todos
        : widget.todos.where((t) => !t.isDone).toList();

    switch (_viewMode) {
      case TodoViewMode.category:
        return CategoryView(
          todos: displayTodos,
          onEdit: widget.onEdit,
          onUpdate: widget.onUpdate,
          onToggle: widget.onToggle,
          onTodoChanged: widget.onTodoChanged,
          onPromote: widget.onPromote,
        );
      case TodoViewMode.priority:
        return PriorityView(
          todos: displayTodos,
          onEdit: widget.onEdit,
          onUpdate: widget.onUpdate,
          onToggle: widget.onToggle,
          onTodoChanged: widget.onTodoChanged,
          onPromote: widget.onPromote,
        );
      case TodoViewMode.delegated:
        return DelegatedView(
          todos: displayTodos,
          onEdit: widget.onEdit,
          onUpdate: widget.onUpdate,
          onToggle: widget.onToggle,
          onTodoChanged: widget.onTodoChanged,
          onPromote: widget.onPromote,
        );
      case TodoViewMode.context:
        return ContextView(
          todos: displayTodos,
          onEdit: widget.onEdit,
          onUpdate: widget.onUpdate,
          onToggle: widget.onToggle,
          onTodoChanged: widget.onTodoChanged,
          onPromote: widget.onPromote,
        );
      case TodoViewMode.dueDate:
        return DueDateView(
          todos: displayTodos,
          onEdit: widget.onEdit,
          onUpdate: widget.onUpdate,
          onToggle: widget.onToggle,
          onTodoChanged: widget.onTodoChanged,
          onPromote: widget.onPromote,
        );
    }
  }
}
