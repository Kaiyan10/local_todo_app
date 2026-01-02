import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_todo/data/todo.dart';
import 'package:flutter_todo/data/todo_repository.dart';
import 'package:flutter_todo/data/database_helper.dart';

@GenerateMocks([DatabaseHelper])
import 'todo_repository_test.mocks.dart';

void main() {
  late TodoRepository repository;
  late MockDatabaseHelper mockDatabaseHelper;

  setUp(() {
    mockDatabaseHelper = MockDatabaseHelper();
    repository = TodoRepository(databaseHelper: mockDatabaseHelper);
  });

  group('TodoRepository Tests', () {
    test('loadTodos returns list of todos', () async {
      final todos = [
        Todo(id: 1, title: 'Test 1', isDone: false),
        Todo(id: 2, title: 'Test 2', isDone: true),
      ];

      when(mockDatabaseHelper.readAllTodos()).thenAnswer((_) async => todos);

      final result = await repository.loadTodos();

      expect(result, todos);
      verify(mockDatabaseHelper.readAllTodos()).called(1);
    });

    test('addTodo calls create on database', () async {
      final todo = Todo(title: 'New Todo');
      when(mockDatabaseHelper.create(todo)).thenAnswer((_) async => 1);

      final id = await repository.addTodo(todo);

      expect(id, 1);
      verify(mockDatabaseHelper.create(todo)).called(1);
    });

    test('updateTodo calls update on database', () async {
      final todo = Todo(id: 1, title: 'Updated Todo');
      when(mockDatabaseHelper.update(todo)).thenAnswer((_) async => 1);

      final result = await repository.updateTodo(todo);

      expect(result, 1);
      verify(mockDatabaseHelper.update(todo)).called(1);
    });

    test('deleteTodo calls delete on database', () async {
      const id = 1;
      when(mockDatabaseHelper.delete(id)).thenAnswer((_) async => 1);

      final result = await repository.deleteTodo(id);

      expect(result, 1);
      verify(mockDatabaseHelper.delete(id)).called(1);
    });

    test(
      'deleteCompletedTodos calls deleteCompletedTodos on database',
      () async {
        when(
          mockDatabaseHelper.deleteCompletedTodos(),
        ).thenAnswer((_) async => 5);

        final result = await repository.deleteCompletedTodos();

        expect(result, 5);
        verify(mockDatabaseHelper.deleteCompletedTodos()).called(1);
      },
    );
  });
}
