import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../data/todo.dart';
import '../widgets/todo_card.dart';

class TodayDueView extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));

    // 1. Blockers: Uncompleted AND (Overdue OR High Priority)
    final blockers = todos.where((todo) {
      if (todo.isDone) return false;
      final isHigh = todo.priority == Priority.high;
      final isOverdue =
          todo.dueDate != null && todo.dueDate!.isBefore(todayStart);
      return isHigh || isOverdue;
    }).toList();

    // 2. Today's Plan: Uncompleted AND (Due Today OR Next Action) AND Not in Blockers
    final todaysPlan = todos.where((todo) {
      if (todo.isDone) return false;
      if (blockers.contains(todo)) return false; // Avoid duplicates

      final isDueToday =
          todo.dueDate != null &&
          todo.dueDate!.year == todayStart.year &&
          todo.dueDate!.month == todayStart.month &&
          todo.dueDate!.day == todayStart.day;

      final isNextAction = todo.category == GtdCategory.nextAction;

      return isDueToday || isNextAction;
    }).toList();

    // 3. Yesterday's Wins: Completed AND Completed Date was Yesterday
    // (Also including Today's completions for "What I did today" context if needed, but requirements say Yesterday)
    // Actually standard daily standup is "What I did Yesterday".
    final yesterdaysWins = todos.where((todo) {
      if (!todo.isDone || todo.lastCompletedDate == null) return false;
      return todo.lastCompletedDate!.isAfter(yesterdayStart) &&
          todo.lastCompletedDate!.isBefore(
            todayStart.add(const Duration(days: 1)),
          );
      // Note: isBefore(tomorrow) covers today too.
      // Strict yesterday would be isBefore(todayStart).
      // But typically "Since last standup" includes today morning.
      // Let's stick to strict yesterday + today for safety so recent wins invoke pride.
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
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSection(context, '🚫 Blockers / Overdue', blockers, Colors.red),
          const SizedBox(height: 16),
          _buildSection(context, '📅 Today\'s Plan', todaysPlan, Colors.blue),
          const SizedBox(height: 16),
          _buildSection(
            context,
            '🎉 Yesterday\'s Wins',
            yesterdaysWins,
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    List<Todo> sectionTodos,
    MaterialColor? themeColor,
  ) {
    final bgColor = themeColor != null
        ? themeColor[100]
        : Theme.of(context).colorScheme.surfaceContainerHighest;
    final textColor = themeColor != null
        ? themeColor[900]
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$title (${sectionTodos.length})',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
        if (sectionTodos.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Nothing here.', style: TextStyle(color: Colors.grey)),
          )
        else
          ...sectionTodos.map(
            (todo) => TodoCard(
              todo: todo,
              onEdit: () => onEdit(todo),
              onCheckboxChanged: (value) => onToggle(todo, value),
              onTodoChanged: onTodoChanged,
            ),
          ),
      ],
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
