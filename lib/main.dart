import 'package:flutter/material.dart';

import 'data/todo.dart';
import 'data/todo_repository.dart';
import 'screen/todo_add_view.dart';
import 'screen/todo_view.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Todo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
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
