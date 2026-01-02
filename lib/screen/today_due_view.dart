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

    // 1. ブロッカー
    final blockers = widget.todos.where((todo) {
      if (todo.isDone) return false;
      final isHigh = todo.priority == Priority.high;
      final isOverdue =
          todo.dueDate != null && todo.dueDate!.isBefore(todayStart);
      return isHigh || isOverdue;
    }).toList();

    // 2. 今日の予定
    final todaysPlan = widget.todos.where((todo) {
      if (todo.isDone) return false;
      if (blockers.contains(todo)) return false;

      final isDueToday =
          todo.dueDate != null &&
          todo.dueDate!.year == todayStart.year &&
          todo.dueDate!.month == todayStart.month &&
          todo.dueDate!.day == todayStart.day;

      final isNextAction = todo.category == GtdCategory.nextAction;

      return isDueToday || isNextAction;
    }).toList();

    // 3. 昨日の成果
    final yesterdaysWins = widget.todos.where((todo) {
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
                blockers,
                todaysPlan,
                yesterdaysWins,
              );
            },
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSectionHeader(
                  context,
                  '🚫 Blockers / Overdue',
                  blockers.length,
                  Colors.red,
                ),
                if (blockers.isEmpty)
                  _buildEmptyState('ブロッカーなし、順調です！', Icons.check_circle_outline),
              ]),
            ),
          ),
          if (blockers.isNotEmpty) _buildSliverList(blockers),
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
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
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
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

  SliverList _buildSliverList(List<Todo> todos) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final todo = todos[index];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          child: TodoCard(
            todo: todo,
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
      }, childCount: todos.length),
    );
  }

  void _copySummaryToClipboard(
    BuildContext context,
    List<Todo> blockers,
    List<Todo> todaysPlan,
    List<Todo> wins,
  ) {
    final buffer = StringBuffer();
    final today = DateFormat.yMd().format(DateTime.now());

    buffer.writeln('# Daily Standup [$today]');
    buffer.writeln();

    buffer.writeln('## 🚫 Blockers');
    if (blockers.isEmpty) {
      buffer.writeln('None');
    } else {
      for (final todo in blockers) {
        buffer.writeln('- [ ] ${todo.title} (Priority: ${todo.priority.name})');
      }
    }
    buffer.writeln();

    buffer.writeln('## 📅 Today\'s Plan');
    if (todaysPlan.isEmpty) {
      buffer.writeln('None');
    } else {
      for (final todo in todaysPlan) {
        buffer.writeln('- [ ] ${todo.title}');
      }
    }
    buffer.writeln();

    buffer.writeln('## 🎉 Achievements (Yesterday/Today)');
    if (wins.isEmpty) {
      buffer.writeln('None');
    } else {
      for (final todo in wins) {
        buffer.writeln('- [x] ${todo.title}');
      }
    }

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Standup summary copied to clipboard!')),
    );
  }
}
