import 'package:flutter/material.dart';

import 'data/todo.dart';
import 'data/todo_repository.dart';
import 'screen/todo_add_view.dart';
import 'screen/todo_view.dart';
import 'screen/settings_view.dart';
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

  Future<void> _save() async {
    await _repository.saveTodos(_todos);
  }

  Future<void> _addTodo() async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const TodoAddView()));
    if (result is Todo) {
      setState(() {
        _todos.add(result);
        _save();
      });
    }
  }

  Future<void> _editTodo(Todo todo) async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => TodoAddView(todo: todo)));
    if (result is Todo) {
      setState(() {
        final index = _todos.indexOf(todo);
        if (index != -1) {
          _todos[index] = result;
          _save();
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
          onUpdate: () {
            setState(() {
              _save();
            });
          },
        ),
      ),
    );
  }

  void _importTodos(List<Todo> newTodos) {
    setState(() {
      _todos.addAll(newTodos);
      _save();
    });
  }

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
                    builder: (context) =>
                        SettingsView(todos: _todos, onImport: _importTodos),
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
        onUpdate: () {
          setState(() {
            _save();
          });
        },
        onEdit: _editTodo,
      ),
    );
  }
}
