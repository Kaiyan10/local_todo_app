import 'package:flutter/material.dart';
import '../data/todo.dart';
import '../data/category_model.dart';
import '../data/settings_service.dart';
import 'todo_add_view.dart';

class WeeklyReviewWizard extends StatefulWidget {
  const WeeklyReviewWizard({
    super.key,
    required this.todos,
    required this.onUpdateTodo,
    required this.onFinish,
  });

  final List<Todo> todos;
  final Function(Todo) onUpdateTodo;
  final VoidCallback onFinish;

  @override
  State<WeeklyReviewWizard> createState() => _WeeklyReviewWizardState();
}

class _WeeklyReviewWizardState extends State<WeeklyReviewWizard> {
  int _currentStep = 0;
  late List<Todo> _localTodos;

  @override
  void initState() {
    super.initState();
    _localTodos = List.from(widget.todos);
  }

  @override
  void didUpdateWidget(WeeklyReviewWizard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.todos != oldWidget.todos) {
      // Logic to preserve local updates if parent updates might be tricky.
      // For now, simpler to just re-sync if parent pushes new data, 
      // but usually this wizard is a modal flow where parent doesn't auto-update it unless we callback.
      // If we callback, parent updates, and might rebuild us.
      // We should probably respect the new list but keep our position.
      _localTodos = List.from(widget.todos);
    }
  }

  List<Todo> get _inboxTodos => _localTodos
      .where((t) => !t.isDone && t.categoryId == 'inbox')
      .toList();

  List<Todo> get _waitingForTodos => _localTodos
      .where((t) => !t.isDone && t.categoryId == 'waitingFor')
      .toList();

  List<Todo> get _somedayTodos => _localTodos
      .where((t) => !t.isDone && t.categoryId == 'someday')
      .toList();

  List<Todo> get _projectTodos => _localTodos
      .where((t) => !t.isDone && t.categoryId == 'project')
      .toList();

  void _nextStep() {
    setState(() {
      _currentStep++;
    });
  }

  // Common update handler
  void _handleUpdate(Todo updated) {
    setState(() {
      final index = _localTodos.indexWhere((t) => t.id == updated.id);
      if (index != -1) {
        _localTodos[index] = updated;
      }
    });
    widget.onUpdateTodo(updated);
  }

  @override
  Widget build(BuildContext context) {
    // Total steps:
    // 0: Welcome
    // 1: Inbox Processing
    // 2: Waiting For Review
    // 3: Someday Review
    // 4: Summary/Finish

    return Scaffold(
      appBar: AppBar(
        title: const Text('週次レビュー'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onFinish,
        ),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(value: (_currentStep + 1) / 6),
          Expanded(child: _buildStepContent()),
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildWelcomeStep();
      case 1:
        return _buildReviewList(
          title: 'Inboxの整理',
          description:
              'Inboxにあるタスクを整理しましょう。\n実行するなら「Next Action」、まだなら「Project」や「Someday」へ。',
          todos: _inboxTodos,
          emptyMessage: 'Inboxは空です！素晴らしい！',
        );

      case 2:
        return _buildProjectReviewList();
      case 3:
        return _buildWaitingForReviewList();
      case 4:
        return _buildReviewList(
          title: 'Someday/Maybeの棚卸し',
          description: '「いつかやる」タスクを見直しましょう。\n今週やるなら「Next Action」へ移動させましょう。',
          todos: _somedayTodos,
          emptyMessage: 'Somedayリストは空です。',
        );
      case 5:
        return _buildSummaryStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildWelcomeStep() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.rate_review, size: 80, color: Colors.blue),
            const SizedBox(height: 24),
            Text(
              '週次レビューを始めましょう',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              '頭の中を空っぽにして、システムを信頼できる状態に戻すための重要なプロセスです。',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryStep() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 80, color: Colors.green),
            const SizedBox(height: 24),
            Text(
              'レビュー完了！',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'お疲れ様でした。これで来週もスッキリとした気持ちで迎えられますね。',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewList({
    required String title,
    required String description,
    required List<Todo> todos,
    required String emptyMessage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                description,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: todos.isEmpty
              ? Center(
                  child: Text(
                    emptyMessage,
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : ListView.separated(
                  itemCount: todos.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final todo = todos[index];
                    return ListTile(
                      title: Text(todo.title),
                      subtitle: Text(
                        todo.categoryId == 'waitingFor' &&
                                todo.delegatee != null
                            ? '${SettingsService().getCategoryName(todo.categoryId)} (待ち: ${todo.delegatee})'
                            : SettingsService().getCategoryName(todo.categoryId),
                      ),
                      trailing: PopupMenuButton<Category>(
                        icon: const Icon(Icons.folder_open),
                        onSelected: (Category newCategory) {
                          final updated = todo.copyWith(categoryId: newCategory.id);
                          _handleUpdate(updated);
                        },
                        itemBuilder: (BuildContext context) {
                          return SettingsService().categories.map((category) {
                            return PopupMenuItem<Category>(
                              value: category,
                              child: Text(category.name),
                            );
                          }).toList();
                        },
                      ),
                      leading: IconButton(
                        icon: const Icon(Icons.check_circle_outline),
                        onPressed: () {
                          // Mark as done
                          final updated = todo.copyWith(isDone: true);
                          _handleUpdate(updated);
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }


  Widget _buildWaitingForReviewList() {
    final todos = _waitingForTodos;

    final Map<String, List<Todo>> grouped = {};
    for (var todo in todos) {
      final key = (todo.delegatee == null || todo.delegatee!.isEmpty) ? '担当者なし' : todo.delegatee!;
      grouped.putIfAbsent(key, () => []).add(todo);
    }
    final sortedKeys = grouped.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Waiting Forの確認', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                '返事待ちのタスクを確認しましょう。\n依頼先ごとに整理されています。',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: todos.isEmpty
              ? const Center(
                  child: Text(
                    '待ち状態のタスクはありません。',
                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : ListView(
                  children: sortedKeys.map((key) {
                    final groupTodos = grouped[key]!;
                    return ExpansionTile(
                      initiallyExpanded: true,
                      title: Text(
                        key,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      children: groupTodos.map((todo) {
                        return ListTile(
                          title: Text(todo.title),
                          subtitle: Text(
                            SettingsService().getCategoryName(todo.categoryId),
                          ),
                          trailing: PopupMenuButton<Category>(
                            icon: const Icon(Icons.folder_open),
                            onSelected: (Category newCategory) {
                              final updated = todo.copyWith(categoryId: newCategory.id);
                              _handleUpdate(updated);
                            },
                            itemBuilder: (BuildContext context) {
                              return SettingsService().categories.map((category) {
                                return PopupMenuItem<Category>(
                                  value: category,
                                  child: Text(category.name),
                                );
                              }).toList();
                            },
                          ),
                          leading: IconButton(
                            icon: const Icon(Icons.check_circle_outline),
                            onPressed: () {
                              final updated = todo.copyWith(isDone: true);
                              _handleUpdate(updated);
                            },
                          ),
                        );
                      }).toList(),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildProjectReviewList() {
    final projects = _projectTodos;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('プロジェクトの棚卸し', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                '進行中のプロジェクトを確認しましょう。\n進捗は順調ですか？次のアクションは決まっていますか？',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: projects.isEmpty
              ? const Center(
                  child: Text(
                    '進行中のプロジェクトはありません。',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              : ListView.separated(
                  itemCount: projects.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final todo = projects[index];
                    final doneCount = todo.subTasks
                        .where((s) => s.isDone)
                        .length;
                    final totalCount = todo.subTasks.length;
                    final progress = totalCount > 0
                        ? doneCount / totalCount
                        : 0.0;

                    return ExpansionTile(
                      title: Text(todo.title),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.grey[200],
                            minHeight: 4,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$doneCount / $totalCount サブタスク完了',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      children: [
                        // Simple subtask list view within the review
                        if (todo.subTasks.isEmpty)
                          const ListTile(
                            title: Text(
                              'サブタスクなし',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ...todo.subTasks
                            .map(
                              (sub) => ListTile(
                                dense: true,
                                leading: Icon(
                                  sub.isDone
                                      ? Icons.check_circle
                                      : Icons.circle_outlined,
                                  size: 16,
                                  color: sub.isDone
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                                title: Text(
                                  sub.title,
                                  style: TextStyle(
                                    decoration: sub.isDone
                                        ? TextDecoration.lineThrough
                                        : null,
                                    color: sub.isDone ? Colors.grey : null,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextButton.icon(
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('プロジェクトを編集'),
                            onPressed: () async {
                              final updated = await Navigator.push<Todo>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TodoAddView(todo: todo),
                                ),
                              );
                              if (!context.mounted) return;
                              if (updated != null) {
                                _handleUpdate(updated);
                              }
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            TextButton(
              onPressed: () {
                setState(() {
                  _currentStep--;
                });
              },
              child: const Text('戻る'),
            )
          else
            const SizedBox.shrink(),
          ElevatedButton(
            onPressed: () {
              if (_currentStep < 5) {
                // Updated max steps
                _nextStep();
              } else {
                widget.onFinish();
              }
            },
            child: Text(_currentStep < 5 ? '次へ' : '完了'),
          ),
        ],
      ),
    );
  }
}
