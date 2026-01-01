import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_todo/data/csv_service.dart';
import 'package:flutter_todo/data/todo.dart';

void main() {
  group('CsvService Tests', () {
    final csvService = CsvService();

    test('generateCsvContent creates correct CSV string', () {
      final todos = [
        Todo(
          id: 1,
          title: 'Task 1',
          category: GtdCategory.inbox,
          isDone: false,
          priority: Priority.low,
          tags: ['t1'],
        ),
        Todo(
          id: 2,
          title: 'Task 2',
          category: GtdCategory.project,
          isDone: true,
          priority: Priority.high,
          tags: ['t2', 'urgent'],
          note: 'A note',
          dueDate: DateTime(2023, 1, 1),
        ),
      ];

      final csv = csvService.generateCsvContent(todos);

      expect(
        csv,
        contains('title,category,isDone,priority,dueDate,note,tags,url'),
      );
      expect(csv, contains('Task 1,inbox,0,low,,,t1,'));
      // Note: DateTime default string format might vary slightly or be precise, standard checks usually safe if simple
      expect(
        csv,
        contains(
          'Task 2,project,1,high,2023-01-01T00:00:00.000,A note,t2;urgent,',
        ),
      );
    });

    test('parseCsvContent parses CSV string correctly', () {
      const csv = '''
title,category,isDone,priority,dueDate,note,tags,url
Task 1,inbox,0,low,,,t1,
Task 2,project,1,high,2023-01-01T00:00:00.000,A note,t2;urgent,
''';

      final todos = csvService.parseCsvContent(csv);

      expect(todos.length, 2);

      expect(todos[0].title, 'Task 1');
      expect(todos[0].category, GtdCategory.inbox);
      expect(todos[0].isDone, false);
      expect(todos[0].priority, Priority.low);
      expect(todos[0].tags, ['t1']);

      expect(todos[1].title, 'Task 2');
      expect(todos[1].category, GtdCategory.project);
      expect(todos[1].isDone, true);
      expect(todos[1].priority, Priority.high);
      expect(todos[1].tags, ['t2', 'urgent']);
      expect(todos[1].note, 'A note');
      expect(todos[1].dueDate, DateTime(2023, 1, 1));
    });

    test('parseCsvContent handles empty input', () {
      final todos = csvService.parseCsvContent('');
      expect(todos, isEmpty);
    });

    test('parseCsvContent handles invalid data gracefully', () {
      // Missing columns
      const csv = '''
title,category
Task 1
''';
      final todos = csvService.parseCsvContent(csv);
      // It should parse what it can or skip/fail gracefully depending on implementation
      // Current implementation checks row length.
      // row[1] category defaults to inbox if missing index?
      // Logic: final categoryName = row.length > 1 ? row[1].toString() : 'inbox';
      // So it handles it safe.

      expect(todos.length, 1);
      expect(todos[0].title, 'Task 1');
      expect(todos[0].category, GtdCategory.inbox);
    });
  });
}
