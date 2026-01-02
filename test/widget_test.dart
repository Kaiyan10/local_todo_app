import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:flutter_todo/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_todo/data/settings_service.dart';
import 'package:flutter_todo/data/todo_repository.dart';
import 'package:flutter_todo/data/todo.dart';

@GenerateMocks([TodoRepository])
import 'widget_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockTodoRepository mockRepository;

  setUpAll(() async {
    // Mock SharedPreferences for SettingsService
    SharedPreferences.setMockInitialValues({});
    // Initialize SettingsService
    await SettingsService().init();
  });

  setUp(() {
    mockRepository = MockTodoRepository();
    // Default stubs
    when(mockRepository.loadTodos()).thenAnswer((_) async => []);
  });

  testWidgets('Add task smoke test', (WidgetTester tester) async {
    // Stub addTodo to return a dummy ID
    when(mockRepository.addTodo(any)).thenAnswer((_) async => 1);

    // Build our app and trigger a frame.
    await tester.pumpWidget(TodoApp(todoRepository: mockRepository));

    // Verify FAB is present
    expect(find.byIcon(Icons.add), findsOneWidget);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    // Verify we are on the Add Task screen
    expect(find.text('Add Task'), findsOneWidget);

    // Find text field
    final titleFinder = find.ancestor(
      of: find.text('タスク名'),
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
    expect(find.text('Local Todo'), findsOneWidget); // AppBar title

    // Verify the new task is displayed
    // Note: Since we mock addTodo/loadTodos, the UI state update depends on MainScreen logic.
    // MainScreen adds result directly to list without reloading from DB in _addTodo.
    expect(find.text('Test New Task'), findsOneWidget);

    // Verify add was called
    verify(mockRepository.addTodo(any)).called(1);
  });
}
