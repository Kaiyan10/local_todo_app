import 'package:flutter/material.dart';
import '../data/todo.dart';
import '../data/settings_service.dart';

class ProcessInboxView extends StatefulWidget {
  const ProcessInboxView({
    super.key,
    required this.todos,
    required this.onUpdateTodo,
    required this.onDeleteTodo,
  });

  final List<Todo> todos;
  final Function(Todo) onUpdateTodo;
  final Function(Todo) onDeleteTodo;

  @override
  State<ProcessInboxView> createState() => _ProcessInboxViewState();
}

class _ProcessInboxViewState extends State<ProcessInboxView> {
  // We maintain a local list of "Inbox" items to process.
  // As we process them, we remove them from this local list (or just iterate index).
  // Be careful about syncing with parent.
  // Ideally, we take the filtered list from parent?
  // Or we just filter locally.

  late List<Todo> _inboxTodos;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _refreshInbox();
  }

  void _refreshInbox() {
    setState(() {
      _inboxTodos = widget.todos
          .where((t) => !t.isDone && t.categoryId == 'inbox')
          .toList();
      // Ensure index is valid
      if (_currentIndex >= _inboxTodos.length) {
        _currentIndex = 0;
      }
    });
  }

  // Since parent widget.todos might update (if we used a Stream), but here we get a static List.
  // We rely on callbacks to update the source of truth, and we remove locally.

  Todo? get _currentTodo {
    if (_inboxTodos.isEmpty || _currentIndex >= _inboxTodos.length) return null;
    return _inboxTodos[_currentIndex];
  }

  void _processDo() {
    // 2 min rule: Do it now, then mark done.
    final todo = _currentTodo;
    if (todo == null) return;

    final updated = todo.copyWith(
      isDone: true,
      lastCompletedDate: DateTime.now(),
    );
    widget.onUpdateTodo(updated);
    _advance();
    _showSnackBar('完了としてマークしました! (2分ルール)');
  }

  Future<void> _processDelegate() async {
    final todo = _currentTodo;
    if (todo == null) return;

    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('タスクを委任する'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: '誰に依頼する?'),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('依頼する'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final updated = todo.copyWith(
        categoryId: 'waitingFor',
        delegatee: result,
      );
      widget.onUpdateTodo(updated);
      _advance();
      _showSnackBar('$result に委任しました');
    }
  }

  Future<void> _processDefer() async {
    final todo = _currentTodo;
    if (todo == null) return;

    // Show dialog to pick Category (Next Action, Project, Someday) and Due Date
    // Simplified: Just 3 buttons for Category, then optional Date picker?
    // Or open a specialized Dialog.

    await showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                '延期選択...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.next_plan),
              title: const Text('Next Action (ASAPでやる)'),
              onTap: () {
                Navigator.pop(ctx);
                _updateCategory(todo, 'nextAction');
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('Project (複数の手順が必要)'),
              onTap: () {
                Navigator.pop(ctx);
                _updateCategory(todo, 'project');
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Schedule (実施日付を設定する)'),
              onTap: () async {
                Navigator.pop(ctx);
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 1)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  final updated = todo.copyWith(
                    dueDate: date,
                    categoryId: 'nextAction', // Usually scheduled items are next actions on that date
                  );
                  widget.onUpdateTodo(updated);
                  _advance();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.cloud_queue),
              title: const Text('Someday / Maybe'),
              onTap: () {
                Navigator.pop(ctx);
                _updateCategory(todo, 'someday');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _updateCategory(Todo todo, String newCategoryId) {
    final updated = todo.copyWith(categoryId: newCategoryId);
    widget.onUpdateTodo(updated);
    _advance();
    _showSnackBar('${SettingsService().getCategoryName(newCategoryId)} に移動しました');
  }

  void _processDelete() {
    final todo = _currentTodo;
    if (todo == null) return;

    widget.onDeleteTodo(
      todo,
    ); // Assuming parent handles deletion or we maintain list
    _advance();
    _showSnackBar('タスクを削除しました');
  }

  void _advance() {
    setState(() {
      _inboxTodos.removeAt(_currentIndex);
      // Index stays at 0 if we remove from front, or stays same index if list shifts.
      // Since we are processing a list, removing the current one shifts subsequent ones down to current index.
      // So _currentIndex doesn't need to change unless it was the last one.
      if (_currentIndex >= _inboxTodos.length) {
        _currentIndex = 0;
      }
    });
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_inboxTodos.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Inbox処理')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 100,
                color: Colors.green,
              ),
              const SizedBox(height: 24),
              Text(
                'Inbox Zero!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              const Text('すべてのアイテムを処理しました。お疲れ様でした!'),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('ダッシュボードに戻る'),
              ),
            ],
          ),
        ),
      );
    }

    final todo = _currentTodo!;

    return Scaffold(
      appBar: AppBar(
        title: Text('Inbox処理 (残り ${_inboxTodos.length} 件)'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value:
                _inboxTodos.length <
                    widget.todos
                        .where(
                          (t) => t.categoryId == 'inbox' && !t.isDone,
                        )
                        .length
                ? 1 -
                      (_inboxTodos.length /
                          ((widget.todos
                                  .where(
                                    (t) =>
                                        t.categoryId == 'inbox' &&
                                        !t.isDone,
                                  )
                                  .length) +
                              0.1))
                : null,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          todo.title,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        if (todo.note != null && todo.note!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            color: Colors.grey[900],
                            child: Text(
                              todo.note!,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          children: todo.tags
                              .map((t) => Chip(label: Text(t)))
                              .toList(),
                        ),
                        const SizedBox(height: 32),
                        const Divider(),
                        const SizedBox(height: 16),
                        Text(
                          'このタスクは2分以内で完了できますか？',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Actions
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _ActionButton(
                        icon: Icons.timer,
                        label: '今すぐやる\n(<2min)',
                        color: Colors.green,
                        onTap: _processDo,
                      ),
                      _ActionButton(
                        icon: Icons.person_add,
                        label: '対応待ちにする',
                        color: Colors.blue,
                        onTap: _processDelegate,
                      ),
                      _ActionButton(
                        icon: Icons.schedule,
                        label: '後でやる',
                        color: Colors.orange,
                        onTap: _processDefer,
                      ),
                      _ActionButton(
                        icon: Icons.delete,
                        label: '削除する',
                        color: Colors.red,
                        onTap: _processDelete,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: color.withOpacity(0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}
