import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/todo_repository.dart';
import '../data/todo.dart';
import '../data/settings_service.dart';
import 'package:intl/intl.dart';

// Services
final todoRepositoryProvider = Provider<TodoRepository>((ref) {
  // Overridden in main.dart if needed, but default is standard repo
  return TodoRepository();
});

final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService();
});

// State
final showCompletedProvider = StateProvider<bool>((ref) => false);

class TodoListNotifier extends AsyncNotifier<List<Todo>> {
  bool _areCompletedTodosLoaded = false;
  bool get areCompletedTodosLoaded => _areCompletedTodosLoaded;

  @override
  Future<List<Todo>> build() async {
    final repository = ref.read(todoRepositoryProvider);
    _areCompletedTodosLoaded = false;
    return await repository.loadTodos();
  }

  Future<void> reload() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      _areCompletedTodosLoaded = false;
      return ref.read(todoRepositoryProvider).loadTodos();
    });
  }

  Future<void> loadCompletedHistory() async {
    if (_areCompletedTodosLoaded) return;
    
    // We don't set global loading state here to avoid flashing the whole list
    // We just append data.
    // If we wanted to show a spinner, we might need a separate "isLoadingHistory" state.
    // For now, mirroring original behavior.
    
    try {
      final repository = ref.read(todoRepositoryProvider);
      final olderTodos = await repository.loadOlderCompletedTodos();
      
      final currentTodos = state.value ?? [];
      state = AsyncValue.data([...currentTodos, ...olderTodos]);
      _areCompletedTodosLoaded = true;
    } catch (e, st) {
      // Just log or could set state to error if we want to show it in UI
      print('Error loading history: $e');
    }
  }

  Future<void> addTodo(Todo todo) async {
    final repository = ref.read(todoRepositoryProvider);
    final id = await repository.addTodo(todo);
    final newTodo = todo.copyWith(id: id);
    
    final currentTodos = state.value ?? [];
    state = AsyncValue.data([...currentTodos, newTodo]);
  }

  Future<void> updateTodo(Todo todo) async {
    final repository = ref.read(todoRepositoryProvider);
    await repository.updateTodo(todo);
    
    final currentTodos = state.value ?? [];
    final index = currentTodos.indexWhere((t) => t.id == todo.id);
    if (index != -1) {
      final newTodos = List<Todo>.from(currentTodos);
      newTodos[index] = todo;
      state = AsyncValue.data(newTodos);
    }
  }

  Future<void> deleteTodo(int id) async {
    final repository = ref.read(todoRepositoryProvider);
    await repository.deleteTodo(id);
    
    final currentTodos = state.value ?? [];
    state = AsyncValue.data(currentTodos.where((t) => t.id != id).toList());
  }
  
  Future<DateTime?> toggleTodo(Todo todo, bool? value) async {
    final repository = ref.read(todoRepositoryProvider);

    if (value == true && todo.repeatPattern != RepeatPattern.none) {
      final baseDate = todo.dueDate ?? DateTime.now();
      final nextDate = todo.repeatPattern.nextDate(baseDate);

      // Create next task
      final nextTodo = Todo(
        title: todo.title,
        categoryId: todo.categoryId,
        isDone: false,
        tags: List.from(todo.tags),
        note: todo.note,
        dueDate: nextDate,
        priority: todo.priority,
        url: todo.url,
        repeatPattern: todo.repeatPattern,
      );

      // Update current task as done
      final updatedTodo = todo.copyWith(
        isDone: true,
        lastCompletedDate: DateTime.now(),
      );
      
      await repository.updateTodo(updatedTodo);
      final id = await repository.addTodo(nextTodo);
      
      final currentTodos = state.value ?? [];
      final newTodos = List<Todo>.from(currentTodos);
      
      final index = newTodos.indexWhere((t) => t.id == todo.id);
      if (index != -1) {
        newTodos[index] = updatedTodo;
      }
      newTodos.add(nextTodo.copyWith(id: id));
      
      state = AsyncValue.data(newTodos);
      return nextDate; // Return for UI feedback
      
    } else {
      // Toggle normal task
      final updatedTodo = todo.copyWith(
        isDone: value ?? false,
        lastCompletedDate: (value ?? false) ? DateTime.now() : null,
      );
      
      await repository.updateTodo(updatedTodo);
      
      final currentTodos = state.value ?? [];
      final index = currentTodos.indexWhere((t) => t.id == todo.id);
      if (index != -1) {
        final newTodos = List<Todo>.from(currentTodos);
        newTodos[index] = updatedTodo;
        state = AsyncValue.data(newTodos);
      }
      return null;
    }
  }

  Future<void> promoteSubTask(Todo parent, Todo subTask) async {
    final repository = ref.read(todoRepositoryProvider);

    // 1. Remove subtask from parent
    final newSubTasks = List<Todo>.from(parent.subTasks);
    newSubTasks.remove(subTask); 
    // Fallback for object identity mismatch if necessary (though usually same instance from UI)
    if (newSubTasks.length == parent.subTasks.length) {
      newSubTasks.removeWhere(
        (t) => t.title == subTask.title && t.dueDate == subTask.dueDate,
      );
    }

    final updatedParent = parent.copyWith(subTasks: newSubTasks);
    await repository.updateTodo(updatedParent);

    // 2. Add subtask as new root task
    final newTodo = Todo(
      title: subTask.title,
      isDone: subTask.isDone,
      note: subTask.note,
      dueDate: subTask.dueDate,
      priority: subTask.priority,
      categoryId: subTask.categoryId,
      tags: subTask.tags,
      url: subTask.url,
      repeatPattern: subTask.repeatPattern,
    );

    final id = await repository.addTodo(newTodo);

    final currentTodos = state.value ?? [];
    final newTodos = List<Todo>.from(currentTodos);
    
    final index = newTodos.indexWhere((t) => t.id == parent.id);
    if (index != -1) {
      newTodos[index] = updatedParent;
    }
    newTodos.add(newTodo.copyWith(id: id));
    
    state = AsyncValue.data(newTodos);
  }
  
  Future<void> importTodos(List<Todo> newTodos) async {
    final repository = ref.read(todoRepositoryProvider);
    final List<Todo> addedTodos = [];
    
    for (var todo in newTodos) {
      final id = await repository.addTodo(todo);
      addedTodos.add(todo.copyWith(id: id));
    }
    
    final currentTodos = state.value ?? [];
    state = AsyncValue.data([...currentTodos, ...addedTodos]);
  }
}

final todoListProvider = AsyncNotifierProvider<TodoListNotifier, List<Todo>>(() {
  return TodoListNotifier();
});
