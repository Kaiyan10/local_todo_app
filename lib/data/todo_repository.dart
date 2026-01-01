import 'todo.dart';
import 'database_helper.dart';

class TodoRepository {
  final DatabaseHelper _databaseHelper;

  TodoRepository({DatabaseHelper? databaseHelper})
    : _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  Future<List<Todo>> loadTodos() async {
    return _databaseHelper.readAllTodos();
  }

  Future<int> addTodo(Todo todo) async {
    return _databaseHelper.create(todo);
  }

  Future<int> updateTodo(Todo todo) async {
    return _databaseHelper.update(todo);
  }

  Future<int> deleteTodo(int id) async {
    return _databaseHelper.delete(id);
  }

  // Deprecated: existing code uses saveTodos with full list.
  // We can keep it or remove it. Ideally remove it to force refactor.
  // But to compile quickly, maybe I should implement it as a batch update?
  // No, let's force refactor for better quality.
}
