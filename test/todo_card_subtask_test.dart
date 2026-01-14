import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_todo/data/todo.dart';
import 'package:flutter_todo/widgets/todo_card.dart';

void main() {
  testWidgets('TodoCard shows add subtask icon when no subtasks', (WidgetTester tester) async {
    final todo = Todo(
      id: 1,
      title: 'Test Task',
      subTasks: [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TodoCard(
            todo: todo,
            onEdit: () {},
            onCheckboxChanged: (_) {},
            onTodoChanged: (_) {},
          ),
        ),
      ),
    );

    // Should show playlist_add icon (or whatever logic we used)
    // We used: hasSubTasks ? (...) : Icons.playlist_add
    expect(find.byIcon(Icons.playlist_add), findsOneWidget);
    expect(find.byTooltip('サブタスクを追加'), findsOneWidget);
  });

  testWidgets('TodoCard expands and shows text field when add subtask icon is clicked', (WidgetTester tester) async {
    final todo = Todo(
      id: 1,
      title: 'Test Task',
      subTasks: [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TodoCard(
            todo: todo,
            onEdit: () {},
            onCheckboxChanged: (_) {},
            onTodoChanged: (_) {},
          ),
        ),
      ),
    );

    // Tap add subtask button
    await tester.tap(find.byIcon(Icons.playlist_add));
    await tester.pump();

    // Verify expanded state: TextField should be visible
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('サブタスクを追加'), findsOneWidget); // Hint text
  });

  testWidgets('TodoCard context menu "Add Subtask" expands the card', (WidgetTester tester) async {
    final todo = Todo(
      id: 1,
      title: 'Test Task',
      subTasks: [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TodoCard(
            todo: todo,
            onEdit: () {},
            onCheckboxChanged: (_) {},
            onTodoChanged: (_) {},
          ),
        ),
      ),
    );

    // Right click / Secondary tap to open context menu
    final gesture = await tester.startGesture(tester.getCenter(find.byType(TodoCard)), kind: PointerDeviceKind.mouse, buttons: kSecondaryButton);
    await gesture.up();
    await tester.pumpAndSettle();

    // Verify context menu item exists
    expect(find.text('サブタスクを追加'), findsOneWidget);

    // Tap the menu item
    await tester.tap(find.text('サブタスクを追加'));
    await tester.pumpAndSettle();

    // Verify expanded state: TextField should be visible
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('Submitting subtask calls onTodoChanged', (WidgetTester tester) async {
    final todo = Todo(
      id: 1,
      title: 'Test Task',
      subTasks: [],
    );

    Todo? updatedTodo;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TodoCard(
            todo: todo,
            onEdit: () {},
            onCheckboxChanged: (_) {},
            onTodoChanged: (newTodo) {
              updatedTodo = newTodo;
            },
          ),
        ),
      ),
    );

    // Expand
    await tester.tap(find.byIcon(Icons.playlist_add));
    await tester.pump();

    // Enter text
    await tester.enterText(find.byType(TextField), 'New Subtask');
    await tester.testTextInput.receiveAction(TextInputAction.done); 
    // Or tap send button
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();

    // Verify callback
    expect(updatedTodo, isNotNull);
    expect(updatedTodo!.subTasks.length, 1);
    expect(updatedTodo!.subTasks.first.title, 'New Subtask');
  });
}
