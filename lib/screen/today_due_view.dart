import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../data/todo.dart';
import '../widgets/todo_card.dart';
import '../widgets/empty_state_widget.dart';

class TodayDueView extends StatefulWidget {
  const TodayDueView({
    super.key,
    required this.todos,
    required this.onEdit,
    required this.onToggle,
    required this.onTodoChanged,
  });

  final List<Todo> todos;
  final Function(Todo) onEdit;
  final Function(Todo, bool?) onToggle;
  final Function(Todo) onTodoChanged;

  @override
  State<TodayDueView> createState() => _TodayDueViewState();
}

class _TodayDueViewState extends State<TodayDueView> {
  // 親のリストを使用するが、楽観的更新（optimistic update）の際に再構築を行う。
  // 独立した状態が必要な場合はローカルコピーを作成するのが理想的だが、
  // 親の変更も反映させたいため、現在のリストを使用する。
  // 更新ストリームがないため、setStateに依存して現在のロジックで再構築するだけで、
  // 即時のフィードバックには十分である。

  @override
  Widget build(BuildContext context) {
    // Re-calculate derived lists on every build
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));

    // Flatten task hierarchy to include subtasks with parent info
    final allTodos = _flattenTodos(widget.todos);

    // 1. Overdue (期限切れ)
    final overdue = allTodos.where((item) {
      final todo = item.todo;
      if (todo.isDone) return false;
      return todo.dueDate != null && todo.dueDate!.isBefore(todayStart);
    }).toList();

    // 2. 今日の予定 (Today's Plan)
    final todaysPlan = allTodos.where((item) {
      final todo = item.todo;
      if (todo.isDone) return false;
      // Overdueに含まれるものは除外
      if (overdue.contains(item)) return false;

      final isDueToday =
          todo.dueDate != null &&
          todo.dueDate!.year == todayStart.year &&
          todo.dueDate!.month == todayStart.month &&
          todo.dueDate!.day == todayStart.day;

      return isDueToday;
    }).toList();

    // 3. ブロッカー (High Priority) - 残りのHigh Priority
    final blockers = allTodos.where((item) {
      final todo = item.todo;
      if (todo.isDone) return false;
      // 既にOverdueかToday's Planに含まれているものは除外
      if (overdue.contains(item)) return false;
      if (todaysPlan.contains(item)) return false;

      return todo.priority == Priority.high;
    }).toList();

    // 4. 昨日の成果
    final yesterdaysWins = allTodos.where((item) {
      final todo = item.todo;
      if (!todo.isDone || todo.lastCompletedDate == null) return false;
      return todo.lastCompletedDate!.isAfter(yesterdayStart) &&
          todo.lastCompletedDate!.isBefore(
            todayStart.add(const Duration(days: 1)),
          );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Standup'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy Summary to Clipboard',
            onPressed: () {
              _copySummaryToClipboard(
                context,
                overdue,
                todaysPlan,
                blockers,
                yesterdaysWins,
              );
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // 1. Overdue
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionHeader(
                  context,
                  '⚠️ Overdue',
                  overdue.length,
                  Colors.red,
                ),
                if (overdue.isEmpty)
                  _buildEmptyState('期限切れタスクはありません！', Icons.check_circle_outline),
              ]),
            ),
          ),
          if (overdue.isNotEmpty) _buildSliverList(overdue),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // 2. Today's Plan
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionHeader(
                  context,
                  '📅 Today\'s Plan',
                  todaysPlan.length,
                  Colors.blue,
                ),
                if (todaysPlan.isEmpty)
                  _buildEmptyState('今日のタスクはすべて完了しました！', Icons.done_all),
              ]),
            ),
          ),
          if (todaysPlan.isNotEmpty) _buildSliverList(todaysPlan),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // 3. Blockers (High Priority)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionHeader(
                  context,
                  '🚫 Blockers (High Priority)',
                  blockers.length,
                  Colors.orange,
                ),
                if (blockers.isEmpty)
                  _buildEmptyState('優先度の高い残タスクはありません。', Icons.verified_user),
              ]),
            ),
          ),
          if (blockers.isNotEmpty) _buildSliverList(blockers),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // 4. Yesterday's Wins
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionHeader(
                  context,
                  '🎉 Yesterday\'s Wins',
                  yesterdaysWins.length,
                  Colors.green,
                ),
                if (yesterdaysWins.isEmpty)
                  _buildEmptyState('昨日の実績はありませんでした。', Icons.history),
              ]),
            ),
          ),
          if (yesterdaysWins.isNotEmpty) _buildSliverList(yesterdaysWins),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: EmptyStateWidget(message: message, icon: icon),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    int count,
    MaterialColor? themeColor,
  ) {
    final primaryColor = themeColor ?? Theme.of(context).colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0, right: 4.0),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  SliverList _buildSliverList(List<({Todo todo, String? parentTitle})> items) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final item = items[index];
        final todo = item.todo;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: TodoCard(
            todo: todo,
            parentTitle: item.parentTitle,
            onEdit: () => widget.onEdit(todo),
            onCheckboxChanged: (value) {
              // 即時のUI応答のための楽観的更新
              setState(() {
                todo.isDone = value ?? false;
              });

              // 実際のロジックを実行
              widget.onToggle(todo, value);
            },
            onTodoChanged: (updatedTodo) {
              widget.onTodoChanged(updatedTodo);
              setState(() {}); // サブタスクの変更を反映するために再構築
            },
          ),
        );
      }, childCount: items.length),
    );
  }

  void _copySummaryToClipboard(
    BuildContext context,
    List<({Todo todo, String? parentTitle})> overdue,
    List<({Todo todo, String? parentTitle})> todaysPlan,
    List<({Todo todo, String? parentTitle})> blockers,
    List<({Todo todo, String? parentTitle})> wins,
  ) {
    final buffer = StringBuffer();
    final today = DateFormat.yMd().format(DateTime.now());

    buffer.writeln('# Daily Standup [$today]');
    buffer.writeln();

    buffer.writeln('## ⚠️ Overdue');
    if (overdue.isEmpty) {
      buffer.writeln('None');
    } else {
      for (final item in overdue) {
        final todo = item.todo;
        final parentInfo = item.parentTitle != null ? ' (Parent: ${item.parentTitle})' : '';
        buffer.writeln('- [ ] ${todo.title} (Due: ${DateFormat.yMd().format(todo.dueDate!)}) $parentInfo');
      }
    }
    buffer.writeln();

    buffer.writeln('## 📅 Today\'s Plan');
    if (todaysPlan.isEmpty) {
      buffer.writeln('None');
    } else {
      for (final item in todaysPlan) {
        final todo = item.todo;
        final parentInfo = item.parentTitle != null ? ' (Parent: ${item.parentTitle})' : '';
        buffer.writeln('- [ ] ${todo.title}$parentInfo');
      }
    }
    buffer.writeln();

    buffer.writeln('## 🚫 Blockers (High Priority)');
    if (blockers.isEmpty) {
      buffer.writeln('None');
    } else {
      for (final item in blockers) {
        final todo = item.todo;
        final parentInfo = item.parentTitle != null ? ' (Parent: ${item.parentTitle})' : '';
        buffer.writeln('- [ ] ${todo.title} (Priority: ${todo.priority.name})$parentInfo');
      }
    }
    buffer.writeln();

    buffer.writeln('## 🎉 Achievements (Yesterday/Today)');
    if (wins.isEmpty) {
      buffer.writeln('None');
    } else {
      for (final item in wins) {
         final todo = item.todo;
         final parentInfo = item.parentTitle != null ? ' (Parent: ${item.parentTitle})' : '';
        buffer.writeln('- [x] ${todo.title}$parentInfo');
      }
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Standup summary copied to clipboard!')),
    );
  }

  List<({Todo todo, String? parentTitle})> _flattenTodos(List<Todo> tasks, [String? parentTitle]) {
    return tasks.expand((t) => [
      (todo: t, parentTitle: parentTitle),
      ..._flattenTodos(t.subTasks, t.title)
    ]).toList();
  }
}
