import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_todo/main.dart';

void main() {
  testWidgets('Add task smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that we start with some default items (e.g. 'Buy milk')
    expect(find.text('Buy milk'), findsOneWidget);

    // Verify FAB is present
    expect(find.byIcon(Icons.add), findsOneWidget);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // Verify we are on the Add Task screen
    expect(find.text('Add Task'), findsOneWidget);
    // There are multiple text fields now, look for the title one specifically
    final titleFinder = find.ancestor(
      of: find.text('Task Title'),
      matching: find.byType(TextField),
    );
    expect(titleFinder, findsOneWidget);

    // Enter text
    await tester.enterText(titleFinder, 'Test New Task');

    final addButtonFinder = find.text('Add');
    await tester.ensureVisible(addButtonFinder);
    await tester.tap(addButtonFinder);
    await tester.pumpAndSettle();

    // Verify we are back on the dashboard
    expect(find.text('Dashboard'), findsOneWidget);

    // Default mock data has 1 inbox item ('Clean the house').
    // Adding one more should make the count 2.
    // We look for the inbox count text.
    expect(find.text('2'), findsOneWidget);
    expect(find.text('Inbox Items'), findsOneWidget);
  });
}
