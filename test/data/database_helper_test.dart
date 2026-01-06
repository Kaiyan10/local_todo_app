import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_todo/data/database_helper.dart';
import 'package:flutter_todo/data/todo.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() {
    DatabaseHelper.resetForTesting();
  });

  Future<void> _seedDatabase(DatabaseHelper dbHelper) async {
    // 1. Active Todo (Incomplete)
    // We need to wait for DB init first or just call create which does it.
    await dbHelper.create(Todo(title: 'Active 1', categoryId: 'inbox', isDone: false));
    
    // 2. Completed Today
    final today = DateTime.now();
    await dbHelper.create(Todo(
      title: 'Done Today', 
      categoryId: 'inbox', 
      isDone: true,
      lastCompletedDate: today
    ));

    // 3. Completed Yesterday (Should be in initial load)
    // Use explicit yesterday date to ensure we match logic
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
    // Add an hour to ensure it's "during" yesterday
    final yesterdayLater = yesterday.add(const Duration(hours: 12));
    
    await dbHelper.create(Todo(
      title: 'Done Yesterday', 
      categoryId: 'inbox', 
      isDone: true,
      lastCompletedDate: yesterdayLater
    ));

    // 4. Completed Older (Should NOT be in initial load)
    // 2 days ago
    final older = yesterday.subtract(const Duration(days: 1));
    await dbHelper.create(Todo(
      title: 'Done Older', 
      categoryId: 'inbox', 
      isDone: true,
      lastCompletedDate: older
    ));
    
    // 5. Active with different category
    await dbHelper.create(Todo(title: 'Active Project', categoryId: 'project', isDone: false));
  }

  test('readInitialTodos loads active tasks and yesterday\'s completions', () async {
    final dbHelper = DatabaseHelper.instance;
    await _seedDatabase(dbHelper);

    final initialTodos = await dbHelper.readInitialTodos();
    
    final titles = initialTodos.map((t) => t.title).toList();
    
    expect(titles, contains('Active 1'));
    expect(titles, contains('Done Today'));
    expect(titles, contains('Done Yesterday'));
    expect(titles, contains('Active Project'));
    
    // IMPORTANT: Done Older should NOT be here
    expect(titles, isNot(contains('Done Older')));
  });

  test('readOlderCompletedTodos loads only older completed tasks', () async {
    final dbHelper = DatabaseHelper.instance;
    await _seedDatabase(dbHelper);

    final olderTodos = await dbHelper.readOlderCompletedTodos();
    
    final titles = olderTodos.map((t) => t.title).toList();
    
    expect(titles, contains('Done Older'));
    // Should NOT contain active or recent ones
    expect(titles, isNot(contains('Active 1')));
    expect(titles, isNot(contains('Done Today')));
    expect(titles, isNot(contains('Done Yesterday')));
  });
  
  test('hasActiveTodosForCategory returns correct boolean', () async {
    final dbHelper = DatabaseHelper.instance;
    await _seedDatabase(dbHelper);
    
    // 'inbox' has 'Active 1'
    expect(await dbHelper.hasActiveTodosForCategory('inbox'), isTrue);
    
    // 'project' has 'Active Project'
    expect(await dbHelper.hasActiveTodosForCategory('project'), isTrue);
    
    // 'empty_cat' has nothing
    expect(await dbHelper.hasActiveTodosForCategory('empty_cat'), isFalse);
    
    // Check completed only
    // Create completed task in new category
    await dbHelper.create(Todo(
        title: 'Done Only', 
        categoryId: 'completed_only', 
        isDone: true, 
        lastCompletedDate: DateTime.now()
    ));
    
    expect(await dbHelper.hasActiveTodosForCategory('completed_only'), isFalse);
  });
}
