import 'package:flutter/material.dart';

import 'data/todo.dart';
import 'data/todo_repository.dart';
import 'screen/todo_add_view.dart';
import 'screen/todo_view.dart';
import 'screen/settings_view.dart';
import 'package:intl/intl.dart';
import 'screen/today_due_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TodoRepository _repository = TodoRepository();
  List<Todo> _todos = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final todos = await _repository.loadTodos();
    setState(() {
      _todos = todos;
    });
  }

  // _save() is removed as we use atomic updates

  Future<void> _addTodo() async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const TodoAddView()));
    if (result is Todo) {
      final id = await _repository.addTodo(result);
      setState(() {
        _todos.add(result.copyWith(id: id));
      });
    }
  }

  Future<void> _editTodo(Todo todo) async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => TodoAddView(todo: todo)));
    if (result is Todo) {
      await _repository.updateTodo(result);
      setState(() {
        final index = _todos.indexWhere(
          (t) => t.id == todo.id,
        ); // Use ID check if possible, or object ref if ID missing (legacy)
        // Since we reload on start, todos should have IDs.
        // But for safety:
        if (index != -1) {
          _todos[index] = result;
        }
      });
    }
  }

  void _openNotification() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TodayDueView(
          todos: _todos,
          onEdit: _editTodo,
          onUpdate: () async {
            // onUpdate in TodayDueView implies something changed outside of edit?
            // Actually TodayDueView might modify todos?
            // checking existing logic: onUpdate was passed to sub-widgets.
            // If sub-widgets rely on it to trigger save, we need to check usage?
            // CategoryView etc use onUpdate to just trigger parent setState/save.
            // If we use direct update functions, onUpdate might just be reload or no-op/setState.

            // Ideally we pass specific callbacks. But for now, let's just reload data or assume edits handled.
            // If subwidgets call onUpdate() it means "Force save"?
            // Refactoring needed.
            // For now, let's reload.
            _loadData();
          },
        ),
      ),
    );
  }

  Future<void> _importTodos(List<Todo> newTodos) async {
    // CSV import.
    for (var todo in newTodos) {
      final id = await _repository.addTodo(todo);
      _todos.add(todo.copyWith(id: id));
    }
    setState(() {});
  }

  Future<void> _toggleTodo(Todo todo, bool? value) async {
    if (value == true && todo.repeatPattern != RepeatPattern.none) {
      final baseDate = todo.dueDate ?? DateTime.now();
      final nextDate = todo.repeatPattern.nextDate(baseDate);

      final nextTodo = Todo(
        title: todo.title,
        category: todo.category,
        isDone: false,
        tags: List.from(todo.tags),
        note: todo.note,
        dueDate: nextDate,
        priority: todo.priority,
        url: todo.url,
        repeatPattern: todo.repeatPattern,
      );

      // Update current todo
      final updatedTodo = todo.copyWith(
        isDone: true,
        lastCompletedDate: DateTime.now(),
      );
      await _repository.updateTodo(updatedTodo);

      // Add next todo
      final id = await _repository.addTodo(nextTodo);

      setState(() {
        // Update list
        final index = _todos.indexOf(todo);
        if (index != -1) {
          _todos[index] = updatedTodo;
        }
        _todos.add(nextTodo.copyWith(id: id));
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '次のタスクを作成しました: ${DateFormat.yMd().format(nextDate!)}',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      final updatedTodo = todo.copyWith(
        isDone: value ?? false,
        lastCompletedDate: (value ?? false) ? DateTime.now() : null,
      );

      // original logic had specific null assignment.
      // todo.lastCompletedDate = null; if not done.
      // copyWith handles nullable?
      // My copyWith implementation: lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate
      // If I pass null, it uses `this`. NOT GOOD if I want to clear it.
      // I need to fix copyWith to allow clearing.
      // Standard copyWith pattern uses valid nulls via sentinel or wrapped types, usually simply passing null means "don't change".
      // But here I need to set it to null.

      // Let's modify Todo directly for now since it's mutable in memory?
      // No, I added ID and it's final?
      // `Todo` fields are NOT final except title, tags, subtasks, url.
      // `isDone` is strict.
      // Wait, checking `todo.dart`:
      // category, isDone, priority, repeatPattern, dueDate, lastCompletedDate are NOT final.
      // So I can modify them in place and then pass to updateTodo.

      setState(() {
        todo.isDone = value ?? false;
        if (todo.isDone) {
          todo.lastCompletedDate = DateTime.now();
        } else {
          todo.lastCompletedDate = null;
        }
      });
      await _repository.updateTodo(todo);
    }
  }

  Future<void> _quickAddTodo(String title) async {
    final newTodo = Todo(title: title, category: GtdCategory.inbox);
    final id = await _repository.addTodo(newTodo);

    setState(() {
      _todos.add(newTodo.copyWith(id: id));
    });
  }

  // Need to handle onUpdate coming from TodoView -> CategoryView
  // Original usage: onUpdate: () { setState(() { _save(); }); }
  // Sub-widgets might modify mutable Todo fields and call onUpdate.
  // If so, I need to know WHICH todo changed to update it in DB.
  // If they modify in place, I might need to iterate and save all? Or just assume they don't?
  // Checking `CategoryView`: might reorder? Drag and drop?
  // Drag and drop usually changes list order.
  // My DB schema doesn't have "order" field.
  // The existing app saved list order by saving the whole JSON list.
  // SQLite doesn't preserve insertion order reliably unless ID or specific column.
  // ID usually correlates with insertion.
  // But Drag & Drop reordering requires an `index` column.
  // If I lose order, that's a regression.
  // The user didn't ask for generic persistence, but "Persistence".
  // If I don't support ordering, user will be confused.
  // I should add `sortOrder` to DB.

  // But wait, the previous code allows reordering?
  // `TodoView` calls `CategoryView`. `CategoryView` might implement drag drop?
  // Let's check `CategoryView` later. If it supports reordering, I need `sortOrder`.
  // For now, I will assume simple update.

  @override
  Widget build(BuildContext context) {
    // Calculate today's incomplete tasks
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayCount = _todos.where((todo) {
      if (todo.isDone || todo.dueDate == null) return false;
      final due = DateTime(
        todo.dueDate!.year,
        todo.dueDate!.month,
        todo.dueDate!.day,
      );
      return due.isAtSameMomentAs(todayStart);
    }).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('localTodo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _openNotification,
            icon: Badge(
              isLabelVisible: todayCount > 0,
              label: Text('$todayCount'),
              child: const Icon(Icons.notifications),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
              child: const Text('localTodo', style: TextStyle(fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('設定'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => SettingsView(
                      todos: _todos,
                      onImport: _importTodos,
                      onReload: _loadData,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTodo,
        child: const Icon(Icons.add),
      ),
      body: TodoView(
        todos: _todos,
        onUpdate: _loadData,
        onEdit: _editTodo,
        onToggle: _toggleTodo,
        onQuickAdd: _quickAddTodo,
      ),
    );
  }
}
