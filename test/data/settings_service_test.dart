import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_todo/data/settings_service.dart';
import 'package:flutter_todo/data/category_model.dart';

void main() {
  group('SettingsService Category Tests', () {
    late SettingsService settingsService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      settingsService = SettingsService();
      await settingsService.init();
    });

    test('Should initialize with system categories', () {
      expect(settingsService.categories.length, SystemCategories.initialCategories.length);
      expect(settingsService.getCategoryName('inbox'), 'Inbox');
    });

    test('Should add a new category', () async {
      final initialLength = settingsService.categories.length;
      await settingsService.addCategory('New Category');
      
      expect(settingsService.categories.length, initialLength + 1);
      final newCategory = settingsService.categories.last;
      expect(newCategory.name, 'New Category');
      expect(newCategory.isSystem, false);
    });

    test('Should update an existing category name', () async {
      await settingsService.addCategory('Old Name');
      final category = settingsService.categories.last;
      
      await settingsService.updateCategory(category.id, 'New Name');
      
      final updatedCategory = settingsService.categories.firstWhere((c) => c.id == category.id);
      expect(updatedCategory.name, 'New Name');
    });

    test('Should delete a custom category', () async {
      await settingsService.addCategory('To Delete');
      final category = settingsService.categories.last;
      final lengthBeforeDelete = settingsService.categories.length;
           
      await settingsService.deleteCategory(category.id);
      
      expect(settingsService.categories.length, lengthBeforeDelete - 1);
      expect(settingsService.categories.any((c) => c.id == category.id), false);
    });

    test('Should NOT delete a system category', () async {
      final inboxId = SystemCategories.inbox;
      final lengthBeforeDelete = settingsService.categories.length;
      
      await settingsService.deleteCategory(inboxId);
      
      expect(settingsService.categories.length, lengthBeforeDelete);
      expect(settingsService.categories.any((c) => c.id == inboxId), true);
    });
    
    test('getCategoryName should return Correct Name or ID if not found', () {
        expect(settingsService.getCategoryName('inbox'), 'Inbox');
        expect(settingsService.getCategoryName('unknown_id'), 'unknown_id');
    });
  });
}
