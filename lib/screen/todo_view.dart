import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/todo.dart';
import '../providers/todo_providers.dart';
import '../widgets/category_view.dart';
import '../widgets/priority_view.dart';
import '../widgets/due_date_view.dart';
import '../widgets/delegated_view.dart';
import '../widgets/context_view.dart';

class TodoView extends ConsumerStatefulWidget {
  const TodoView({
    super.key,
    required this.todos,
    required this.onEdit,
  });

  final List<Todo> todos;
  final Function(Todo) onEdit;

  @override
  ConsumerState<TodoView> createState() => _TodoViewState();
}

class _TodoViewState extends ConsumerState<TodoView> {
  int _selectedIndex = 0; // 0: Category, 1: Priority, 2: Due Date, 3: Delegated, 4: Context
  final TextEditingController _quickAddController = TextEditingController();

  @override
  void dispose() {
    _quickAddController.dispose();
    super.dispose();
  }

  Future<void> _handleQuickAdd(String value) async {
    if (value.isNotEmpty) {
      final newTodo = Todo(title: value, categoryId: 'inbox');
      await ref.read(todoListProvider.notifier).addTodo(newTodo);
      _quickAddController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // View Switcher (Segmented Button)
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment(
                value: 0,
                label: Text('カテゴリ', softWrap: false),
                icon: Icon(Icons.category),
              ),
              ButtonSegment(
                value: 1,
                label: Text('優先度', softWrap: false),
                icon: Icon(Icons.flag),
              ),
              ButtonSegment(
                value: 2,
                label: Text('期限', softWrap: false),
                icon: Icon(Icons.calendar_today),
              ),
              ButtonSegment(
                value: 3,
                label: Text('対応待ち', softWrap: false),
                icon: Icon(Icons.people),
              ),
              ButtonSegment(
                value: 4,
                label: Text('コンテキスト', softWrap: false),
                icon: Icon(Icons.label),
              ),
            ],
            selected: {_selectedIndex},
            onSelectionChanged: (Set<int> newSelection) {
              setState(() {
                _selectedIndex = newSelection.first;
              });
            },
            showSelectedIcon: false,
          ),
        ),
        
        // Quick Add Field
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: TextField(
            controller: _quickAddController,
            decoration: InputDecoration(
              hintText: 'クイック追加 (EnterでInboxに追加)',
              prefixIcon: const Icon(Icons.add),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            ),
            onSubmitted: _handleQuickAdd,
          ),
        ),

        // Main Content (IndexedStack for KeepAlive)
        Expanded(
          child: IndexedStack(
            index: _selectedIndex,
            children: [
              CategoryView(
                todos: widget.todos,
                onEdit: widget.onEdit,
              ),
              PriorityView(
                todos: widget.todos,
                onEdit: widget.onEdit,
              ),
              DueDateView(
                todos: widget.todos,
                onEdit: widget.onEdit,
              ),
              DelegatedView(
                todos: widget.todos,
                onEdit: widget.onEdit,
              ),
              ContextView(
                todos: widget.todos,
                onEdit: widget.onEdit,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
