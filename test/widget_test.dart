import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_todo/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_todo/data/settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Mock SharedPreferences for SettingsService
    SharedPreferences.setMockInitialValues({});
    // Initialize SettingsService
    await SettingsService().init();
  });

  testWidgets('Add task smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TodoApp());

    // Verify that we start with no items or handle empty state
    // expect(find.text('Buy milk'), findsOneWidget); // Removed as DB might be empty

    // Verify FAB is present
    expect(find.byIcon(Icons.add), findsOneWidget);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // Verify we are on the Add Task screen
    expect(find.text('Add Task'), findsOneWidget);
    // There are multiple text fields now, look for the title one specifically
    final titleFinder = find.ancestor(
      of: find.text('タスク名'), // Updated to match actual UI label
      matching: find.byType(TextField),
    );
    expect(titleFinder, findsOneWidget);

    // Enter text
    await tester.enterText(titleFinder, 'Test New Task');

    // Tap Save/Add button
    final addButtonFinder = find.byType(ElevatedButton);
    await tester.ensureVisible(addButtonFinder);
    await tester.tap(addButtonFinder);
    await tester.pumpAndSettle();

    // Verify we are back on the dashboard
    expect(find.text('Dashboard'), findsOneWidget);

    // Verify the new task is displayed
    expect(find.text('Test New Task'), findsOneWidget);
  });
}
