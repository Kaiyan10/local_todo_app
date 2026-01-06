import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_todo/data/category_model.dart';

void main() {
  group('Category Model Tests', () {
    test('Category properties should be correct', () {
      final category = Category(id: 'test_id', name: 'Test Name', isSystem: false);
      expect(category.id, 'test_id');
      expect(category.name, 'Test Name');
      expect(category.isSystem, false);
    });

    test('Category.fromJson and toJson should work', () {
      final category = Category(id: 'test_id', name: 'Test Name', isSystem: true);
      final json = category.toJson();
      expect(json['id'], 'test_id');
      expect(json['name'], 'Test Name');
      expect(json['isSystem'], true);

      final fromJson = Category.fromJson(json);
      expect(fromJson.id, category.id);
      expect(fromJson.name, category.name);
      expect(fromJson.isSystem, category.isSystem);
    });
  });

  group('SystemCategories Tests', () {
    test('Should contain default system categories', () {
      expect(SystemCategories.inbox, 'inbox');
      expect(SystemCategories.nextAction, 'nextAction');
      expect(SystemCategories.initialCategories.length, greaterThan(0));
      
      final inbox = SystemCategories.initialCategories.firstWhere((c) => c.id == SystemCategories.inbox);
      expect(inbox.isSystem, true);
    });
  });
}
