import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_todo/data/todo.dart';

void main() {
  group('Todo Model Tests', () {
    test('fromJson creates correct Todo object', () {
      final json = {
        'id': 1,
        'title': 'Test Todo',
        'category': 'inbox',
        'isDone': 0, // int from DB
        'tags': ['tag1', 'tag2'],
        'priority': 'high',
        'repeatPattern': 'daily',
      };

      final todo = Todo.fromJson(json);

      expect(todo.id, 1);
      expect(todo.title, 'Test Todo');
      expect(todo.categoryId, 'inbox');
      expect(todo.isDone, false);
      expect(todo.tags, ['tag1', 'tag2']);
      expect(todo.priority, Priority.high);
      expect(todo.repeatPattern, RepeatPattern.daily);
    });

    test('fromJson handles boolean isDone from JSON', () {
      final json = {'title': 'Test Todo', 'isDone': true};

      final todo = Todo.fromJson(json);
      expect(todo.isDone, true);
    });

    test('toJson returns correct Map', () {
      final todo = Todo(
        id: 1,
        title: 'Test Todo',
        categoryId: 'project',
        isDone: true,
        priority: Priority.medium,
        repeatPattern: RepeatPattern.weekly,
        tags: ['urgent'],
      );

      final json = todo.toJson();

      expect(json['id'], 1);
      expect(json['title'], 'Test Todo');
      expect(json['category'], 'project');
      expect(json['isDone'], true);
      expect(json['priority'], 'medium');
      expect(json['repeatPattern'], 'weekly');
      expect(json['tags'], ['urgent']);
    });

    test('copyWith updates fields correctly', () {
      final todo = Todo(title: 'Original');
      final updated = todo.copyWith(title: 'Updated', isDone: true);

      expect(updated.title, 'Updated');
      expect(updated.isDone, true);
      expect(updated.categoryId, todo.categoryId); // Should remain default
    });
  });

  group('RepeatPattern Tests', () {
    test('daily adds 1 day', () {
      final date = DateTime(2023, 1, 1);
      final next = RepeatPattern.daily.nextDate(date);
      expect(next, DateTime(2023, 1, 2));
    });

    test('weekly adds 7 days', () {
      final date = DateTime(2023, 1, 1);
      final next = RepeatPattern.weekly.nextDate(date);
      expect(next, DateTime(2023, 1, 8));
    });

    test('monthly adds 1 month', () {
      final date = DateTime(2023, 1, 31);
      final next = RepeatPattern.monthly.nextDate(date);
      // Current simple impl: month + 1. 2023-01-31 -> 2023-02-31 (which normalizes to March 3 or 2 depending on leap year etc in Dart DateTime constructor behavior)
      // Actually Dart DateTime handles overflow by moving into next month.
      // 2023-02-31 doesn't exist. 2023-02-28 is end.
      // DateTime(2023, 2, 31) -> March 3rd (non-leap year)
      // Let's verify what the current implementation does.
      // It does: DateTime(current.year, current.month + 1, current.day...)

      expect(next?.year, 2023);
      expect(next?.month, 3); // Because Feb does not have 31 days
      // This confirms the "simple implementation" note in the code.
    });

    test('none returns null', () {
      final date = DateTime(2023, 1, 1);
      expect(RepeatPattern.none.nextDate(date), isNull);
    });
  });
}
