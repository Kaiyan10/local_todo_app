import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'data/todo.dart';
import 'data/database_helper.dart';
import 'data/todo_repository.dart';
import 'data/settings_service.dart';
import 'providers/todo_providers.dart';
import 'screen/todo_add_view.dart';
import 'screen/todo_view.dart';
import 'screen/settings_view.dart';
import 'package:intl/intl.dart';
import 'screen/today_due_view.dart';
import 'screen/weekly_review_wizard.dart';
import 'screen/project_dashboard_view.dart';
import 'screen/process_inbox_view.dart';

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/services.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await windowManager.ensureInitialized();

    WindowOptions windowOptions = const WindowOptions(
      size: Size(1280, 720),
      minimumSize: Size(600, 400),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );

    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  // DatabaseHelper initializes lazily via the database getter
  await SettingsService().init();
  
  runApp(const ProviderScope(child: TodoApp()));
}

class TodoApp extends ConsumerStatefulWidget {
  final TodoRepository? todoRepository;
  const TodoApp({super.key, this.todoRepository});

  @override
  ConsumerState<TodoApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<TodoApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  Widget build(BuildContext context) {
    // If a repository was passed (e.g. from tests), we need to ensure the provider uses it.
    // However, ProviderScope is above us. We can't override it here easily unless we add another scope.
    // Ideally, tests should wrap TodoApp in ProviderScope with overrides.
    // But for backward compatibility with existing tests that just instantiate TodoApp:
    
    // Actually, best practice for tests is to wrap IN THE TEST.
    // So we should modify widget_test.dart later.
    // For now, TodoApp just builds MaterialApp.
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: _themeMode,
      home: MainScreen(
        onThemeChanged: (mode) {
          setState(() {
            _themeMode = mode;
          });
        },
        currentThemeMode: _themeMode,
      ),
    );
  }
}

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({
    super.key,
    required this.onThemeChanged,
    required this.currentThemeMode,
  });

  final Function(ThemeMode) onThemeChanged;
  final ThemeMode currentThemeMode;

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  // Logic moved to TodoListNotifier

  @override
  void initState() {
    super.initState();
    // No explicit load needed, watching the provider triggers build & load.
  }

  Future<void> _addTodo() async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const TodoAddView()));
    if (result is Todo) {
      await ref.read(todoListProvider.notifier).addTodo(result);
    }
  }

  Future<void> _editTodo(Todo todo) async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => TodoAddView(todo: todo)));
    if (result is Todo) {
      await ref.read(todoListProvider.notifier).updateTodo(result);
    }
  }

  Future<void> _updateTodoDirectly(Todo todo) async {
    await ref.read(todoListProvider.notifier).updateTodo(todo);
  }

  Future<void> _toggleTodo(Todo todo, bool? value) async {
    final notifier = ref.read(todoListProvider.notifier);
    final nextDate = await notifier.toggleTodo(todo, value);
    
    if (nextDate != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '次のタスクを作成しました: ${DateFormat.yMd().format(nextDate)}',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _quickAddTodo(String title) async {
    final newTodo = Todo(title: title, categoryId: 'inbox');
    await ref.read(todoListProvider.notifier).addTodo(newTodo);
  }

  Future<void> _deleteTodo(Todo todo) async {
    if (todo.id != null) {
      await ref.read(todoListProvider.notifier).deleteTodo(todo.id!);
    }
  }
  
  Future<void> _loadCompletedHistory() async {
    await ref.read(todoListProvider.notifier).loadCompletedHistory();
    if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('過去の履歴を読み込みました'),
            duration: Duration(seconds: 1),
          ),
        );
    }
  }
  
  // Reload
  Future<void> _loadData() async {
    await ref.read(todoListProvider.notifier).reload();
  }

  Future<void> _promoteSubTask(Todo parent, Todo subTask) async {
    await ref.read(todoListProvider.notifier).promoteSubTask(parent, subTask);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('"${subTask.title}" をタスクに昇格しました')));
    }
  }

  Future<void> _importTodos(List<Todo> newTodos) async {
    await ref.read(todoListProvider.notifier).importTodos(newTodos);
  }

  void _openNotification() {
    final asyncTodos = ref.read(todoListProvider);
    // Best effort: pass current data. If loading, pass empty?
    final todos = asyncTodos.value ?? [];
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TodayDueView(
          todos: todos,
          onEdit: _editTodo,
          onToggle: _toggleTodo,
          onTodoChanged: _updateTodoDirectly,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncTodos = ref.watch(todoListProvider);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyN, alt: true): _addTodo,
      },
      child: Focus(
        autofocus: true,
        child: _buildScaffold(context, asyncTodos),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context, AsyncValue<List<Todo>> asyncTodos) {
      final todos = asyncTodos.value ?? [];
      
      // Calculate today's incomplete tasks
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayCount = todos.where((todo) {
        if (todo.isDone || todo.dueDate == null) return false;
        final due = DateTime(
          todo.dueDate!.year,
          todo.dueDate!.month,
          todo.dueDate!.day,
        );
        return due.isAtSameMomentAs(todayStart);
      }).length;

      // Filter logic for Display
      final showCompleted = ref.watch(showCompletedProvider);
      final displayTodos = showCompleted
          ? todos
          : todos.where((t) => !t.isDone).toList();

      return Scaffold(
      appBar: AppBar(
        title: const Text('localTodo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Show/Hide Completed Toggle
          IconButton(
            tooltip: showCompleted ? '完了を隠す' : '完了を表示',
            onPressed: () {
               ref.read(showCompletedProvider.notifier).state = !showCompleted;
            },
            icon: Icon(showCompleted ? Icons.visibility : Icons.visibility_off),
          ),
          IconButton(
            onPressed: _openNotification,
            icon: Badge(
              isLabelVisible: todayCount > 0,
              label: Text('$todayCount'),
              child: const Icon(Icons.notifications),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
              child: const Text('localTodo', style: TextStyle(fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.rate_review),
              title: const Text('週次レビュー'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => WeeklyReviewWizard(
                      todos: todos,
                      onUpdateTodo: _updateTodoDirectly,
                      onFinish: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('設定'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => SettingsView(
                      todos: todos,
                      onImport: _importTodos,
                      onReload: _loadData,
                      currentThemeMode: widget.currentThemeMode,
                      onThemeChanged: widget.onThemeChanged,
                    ),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.dashboard_customize),
              title: const Text('プロジェクト・ポートフォリオ'),
              tileColor: Theme.of(
                context,
              ).colorScheme.primaryContainer.withOpacity(0.3),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ProjectDashboard(
                      todos: todos,
                      onEdit: _editTodo,
                      onUpdate: _loadData,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.speed),
              title: const Text('Inbox Zero (処理)'),
              tileColor: Theme.of(
                context,
              ).colorScheme.tertiaryContainer.withOpacity(0.3),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ProcessInboxView(
                      todos: todos,
                      onUpdateTodo: _updateTodoDirectly,
                      onDeleteTodo: _deleteTodo,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTodo,
        child: const Icon(Icons.add),
      ),
      body: asyncTodos.when(
        data: (todos) => TodoView(
          todos: displayTodos,
          onEdit: _editTodo,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
