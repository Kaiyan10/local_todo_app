import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'todo.dart';

import 'dummy_data.dart';

class TodoRepository {
  Future<String> _getFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/todos.json';
  }

  Future<List<Todo>> loadTodos() async {
    try {
      final path = await _getFilePath();
      final file = File(path);

      if (!await file.exists()) {
        return dummyTodos;
      }

      final content = await file.readAsString();
      final List<dynamic> jsonList = jsonDecode(content);
      return jsonList.map((json) => Todo.fromJson(json)).toList();
    } catch (e) {
      // In case of error (corruption, etc.), return empty list
      print('Error loading todos: $e');
      return [];
    }
  }

  Future<void> saveTodos(List<Todo> todos) async {
    try {
      final path = await _getFilePath();
      final file = File(path);
      final jsonList = todos.map((todo) => todo.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      print('Error saving todos: $e');
    }
  }
}
