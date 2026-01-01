import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'todo.dart';
import 'dummy_data.dart';

class TodoRepository {
  static const String _keyTodos = 'todos';

  Future<List<Todo>> loadTodos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_keyTodos);

      if (jsonString == null) {
        return dummyTodos;
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => Todo.fromJson(json)).toList();
    } catch (e) {
      print('Error loading todos: $e');
      return dummyTodos;
    }
  }

  Future<void> saveTodos(List<Todo> todos) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = todos.map((todo) => todo.toJson()).toList();
      await prefs.setString(_keyTodos, jsonEncode(jsonList));
    } catch (e) {
      print('Error saving todos: $e');
    }
  }
}
