import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_todo/data/todo.dart';
import 'package:flutter_todo/data/settings_service.dart';
import 'package:flutter_todo/screen/todo_add_view.dart';
import 'package:flutter_todo/providers/todo_providers.dart';
import '../widget_test.mocks.dart';

void main() {
  late MockTodoRepository mockRepository;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await SettingsService().init();
  });

  setUp(() {
    mockRepository = MockTodoRepository();
  });

  testWidgets('Assignee selection appears only for WaitingFor category', (WidgetTester tester) async {
    // Setup existing todos to provide assignee suggestions
    when(mockRepository.loadTodos()).thenAnswer((_) async => [
      Todo(title: 'Task 1', delegatee: 'Alice'),
      Todo(title: 'Task 2', delegatee: 'Bob'),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todoRepositoryProvider.overrideWithValue(mockRepository),
        ],
        child: const MaterialApp(
          home: TodoAddView(),
        ),
      ),
    );
    await tester.pumpAndSettle(); // Allow Riverpod to load data

    // Initially "Inbox", so assignee field should NOT be visible
    expect(find.text('担当者 (Delegatee)'), findsNothing);

    // Switch to "Waiting For" (assuming 'Waiting For' label exists in chips)
    // Note: The chips display the Category Name. SystemCategories.waitingFor name is 'Waiting For'.
    await tester.tap(find.text('Waiting For'));
    await tester.pumpAndSettle();

    // Assignee field should now be visible
    expect(find.text('担当者 (Delegatee)'), findsOneWidget);

    // Test Autocomplete
    // Find the TextField inside the Autocomplete
    final assigneeField = find.ancestor(
      of: find.text('担当者 (Delegatee)'), 
      matching: find.byType(TextField)
    );
    
    // Type partial name 'Al'
    await tester.enterText(assigneeField, 'Al');
    await tester.pumpAndSettle();

    // Suggestion 'Alice' should appear
    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bob'), findsNothing);

    // Tap suggestion
    await tester.tap(find.text('Alice'));
    await tester.pumpAndSettle();

    // Field should contain 'Alice'
    expect(find.text('Alice'), findsOneWidget);
  });
}
