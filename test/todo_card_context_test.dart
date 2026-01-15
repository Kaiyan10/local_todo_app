import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/gestures.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_todo/data/settings_service.dart';
import 'package:flutter_todo/data/todo_repository.dart';
import 'package:flutter_todo/providers/todo_providers.dart';
import 'package:flutter_todo/data/todo.dart';
import 'package:flutter_todo/widgets/todo_card.dart';

@GenerateMocks([TodoRepository])
import 'todo_card_context_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockTodoRepository mockRepository;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({
      'custom_contexts': ['@Work', '@Home']
    });
    await SettingsService().init();
  });

  setUp(() {
    mockRepository = MockTodoRepository();
  });

  testWidgets('Right-click on TodoCard opens context menu and allows toggling context', (WidgetTester tester) async {
    // Set screen size to ensure elements are visible
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final initialTodo = Todo(
      id: 1,
      title: 'Context Test Task',
      categoryId: 'inbox',
      tags: [],
    );

    // Mock updateTodo to capture the change
    when(mockRepository.updateTodo(any)).thenAnswer((_) async => 1);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          todoRepositoryProvider.overrideWithValue(mockRepository),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: TodoCard(
              todo: initialTodo,
              onEdit: () {},
              onCheckboxChanged: (_) {},
              onTodoChanged: (updated) {
                 // For the test, we manually call the repository update if we can, 
                 // but TodoCard calls onTodoChanged.
                 // In the app, onTodoChanged calls provider using repository.
                 // Here we simulate the callback action.
                 mockRepository.updateTodo(updated);
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Find the TodoCard
    final cardFinder = find.text('Context Test Task');
    expect(cardFinder, findsOneWidget);

    // Right-click (secondary tap)
    await tester.tap(cardFinder, buttons: kSecondaryButton);
    await tester.pumpAndSettle();

    // Verify Menu opens
    expect(find.text('コンテキスト'), findsOneWidget);

    // Tap 'コンテキスト'
    await tester.tap(find.text('コンテキスト'));
    await tester.pumpAndSettle();

    // Verify Dialog opens with contexts
    expect(find.text('コンテキストを編集'), findsOneWidget);
    expect(find.text('@Work'), findsOneWidget);
    expect(find.text('@Home'), findsOneWidget);
    expect(find.text('新規'), findsOneWidget);

    // Tap @Work to toggle it ON
    await tester.tap(find.text('@Work'));
    await tester.pump(); // Rebuild for local state update

    // Verify updateTodo was called with @Work added
    final verification = verify(mockRepository.updateTodo(captureAny));
    verification.called(1);
    final updatedTodo = verification.captured.first as Todo;
    expect(updatedTodo.tags, contains('@Work'));

    // Close dialog
    await tester.tap(find.text('閉じる'));
    await tester.pumpAndSettle();
    
    // Dialog should be closed
    expect(find.text('コンテキストを編集'), findsNothing);
  });
}
