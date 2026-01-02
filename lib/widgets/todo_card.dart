import 'package:flutter/material.dart';
import '../screen/todo_add_view.dart';
import '../data/todo.dart';
import 'package:intl/intl.dart';

final DateFormat _dateFormat = DateFormat('yyyy/MM/dd');

class TodoCard extends StatefulWidget {
  const TodoCard({
    super.key,
    required this.todo,
    required this.onEdit,
    required this.onCheckboxChanged,
    this.onTodoChanged,
    this.onPromote,
  });

  final Todo todo;
  final VoidCallback onEdit;
  final ValueChanged<bool?> onCheckboxChanged;
  final Function(Todo)? onTodoChanged;
  final Function(Todo, Todo)? onPromote;

  @override
  State<TodoCard> createState() => _TodoCardState();
}

class _TodoCardState extends State<TodoCard> {
  bool _isExpanded = false;
  final TextEditingController _subTaskController = TextEditingController();

  @override
  void dispose() {
    _subTaskController.dispose();
    super.dispose();
  }

  void _submitSubTask(String value) {
    if (value.trim().isEmpty) return;
    if (widget.onTodoChanged == null) return;

    final newSubTask = Todo(
      title: value.trim(),
      category: widget.todo.category,
      priority: widget.todo.priority,
      tags: List.from(widget.todo.tags),
    );
    final newSubTasks = List<Todo>.from(widget.todo.subTasks)..add(newSubTask);
    final updatedTodo = widget.todo.copyWith(subTasks: newSubTasks);
    widget.onTodoChanged!(updatedTodo);
    _subTaskController.clear();
  }

  Color? _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.high:
        return Colors.redAccent;
      case Priority.medium:
        return Colors.orangeAccent;
      case Priority.low:
        return Colors.green;
      case Priority.none:
        return null;
    }
  }

  Widget _buildStyledCard(Widget child) {
    final priorityColor = _getPriorityColor(widget.todo.priority);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: priorityColor != null
              ? Border(left: BorderSide(color: priorityColor, width: 4))
              : null,
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: [
        _buildCardContent(context, expand: true),
        if (_isExpanded && widget.todo.subTasks.isNotEmpty)
          ...widget.todo.subTasks.asMap().entries.map((entry) {
            final index = entry.key;
            final subTask = entry.value;
            return Padding(
              padding: const EdgeInsets.only(
                left: 16.0,
                right: 16.0,
                bottom: 4.0,
              ),
              child: InkWell(
                onTap: () async {
                  if (widget.onTodoChanged == null) return;
                  final updatedSubTask = await Navigator.push<Todo>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TodoAddView(todo: subTask),
                    ),
                  );
                  if (updatedSubTask != null) {
                    final updatedSubTasks = List<Todo>.from(
                      widget.todo.subTasks,
                    );
                    updatedSubTasks[index] = updatedSubTask;
                    final updatedTodo = widget.todo.copyWith(
                      subTasks: updatedSubTasks,
                    );
                    widget.onTodoChanged!(updatedTodo);
                  }
                },
                child: Row(
                  children: [
                    SizedBox(
                      width: 24,
                      height: 24,
                      child: Checkbox(
                        value: subTask.isDone,
                        onChanged: (val) {
                          if (widget.onTodoChanged != null && val != null) {
                            final updatedSub = subTask.copyWith(isDone: val);
                            final updatedSubTasks = List<Todo>.from(
                              widget.todo.subTasks,
                            );
                            updatedSubTasks[index] = updatedSub;
                            final updatedTodo = widget.todo.copyWith(
                              subTasks: updatedSubTasks,
                            );
                            widget.onTodoChanged!(updatedTodo);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        subTask.title,
                        style: TextStyle(
                          decoration: subTask.isDone
                              ? TextDecoration.lineThrough
                              : null,
                          color: subTask.isDone
                              ? Theme.of(context).disabledColor
                              : null,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (widget.onPromote != null)
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 16),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'promote',
                            child: const Text('タスクに昇格'),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'promote') {
                            widget.onPromote!(widget.todo, subTask);
                          }
                        },
                      ),
                  ],
                ),
              ),
            );
          }),
        if (_isExpanded)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                const Icon(Icons.add, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _subTaskController,
                    decoration: const InputDecoration(
                      hintText: 'サブタスクを追加',
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onSubmitted: _submitSubTask,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, size: 20),
                  onPressed: () => _submitSubTask(_subTaskController.text),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        if (_isExpanded) const SizedBox(height: 8),
      ],
    );

    // サブタスクがない場合でも、スタイル付きカードを使用する。
    // サブタスクがある場合は、Columnをラップするスタイル付きカードを使用する。

    // ロジック確認: 元のコードはサブタスクがない場合に直接 _buildCardContent を返していた（そこでCardをラップしていた）。
    // 現在はすべてを _buildStyledCard でラップする。

    return _buildStyledCard(content);
  }

  Widget _buildCardContent(BuildContext context, {required bool expand}) {
    final hasSubTasks = widget.todo.subTasks.isNotEmpty;

    // 注記: ここではもう Card を返さず、コンテンツ (ListTile) のみを返す。
    // ラッパーの build メソッドが Card を処理する。

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 8.0,
      ),
      title: _buildTitle(),
      subtitle: _buildSubtitle(context),
      leading: Transform.scale(
        scale: 1.2,
        child: Checkbox(
          shape: const CircleBorder(),
          value: widget.todo.isDone,
          onChanged: widget.onCheckboxChanged,
          activeColor: Theme.of(context).primaryColor,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasSubTasks)
            IconButton(
              icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: widget.onEdit,
          ),
        ],
      ),
      onTap: (hasSubTasks)
          ? () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            }
          : null,
    );
  }

  Widget _buildTitle() {
    return Text(
      widget.todo.title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        decoration: widget.todo.isDone ? TextDecoration.lineThrough : null,
        color: widget.todo.isDone ? Theme.of(context).disabledColor : null,
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    final subTaskCount = widget.todo.subTasks.length;
    final doneCount = widget.todo.subTasks.where((s) => s.isDone).length;
    final progress = subTaskCount > 0 ? doneCount / subTaskCount : 0.0;

    // 表示するメタデータがあるか確認
    final hasMetadata =
        widget.todo.dueDate != null ||
        widget.todo.repeatPattern != RepeatPattern.none ||
        widget.todo.priority != Priority.none ||
        (widget.todo.category == GtdCategory.waitingFor &&
            widget.todo.delegatee != null) ||
        widget.todo.subTasks.isNotEmpty ||
        (widget.todo.note != null && widget.todo.note!.isNotEmpty);

    if (!hasMetadata) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.todo.note != null && widget.todo.note!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                widget.todo.note!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (widget.todo.dueDate != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: widget.todo.isDone
                          ? Theme.of(context).disabledColor
                          : (widget.todo.dueDate!.isBefore(DateTime.now()) &&
                                    !widget.todo.isDone
                                ? Theme.of(context).colorScheme.error
                                : Theme.of(context).colorScheme.primary),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _dateFormat.format(widget.todo.dueDate!),
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.todo.isDone
                            ? Theme.of(context).disabledColor
                            : (widget.todo.dueDate!.isBefore(DateTime.now()) &&
                                      !widget.todo.isDone
                                  ? Theme.of(context).colorScheme.error
                                  : null),
                      ),
                    ),
                  ],
                ),
              if (widget.todo.repeatPattern != RepeatPattern.none)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.repeat,
                      size: 14,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.todo.repeatPattern.displayName,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              if (widget.todo.category == GtdCategory.waitingFor &&
                  widget.todo.delegatee != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_outline,
                      size: 14,
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '待ち: ${widget.todo.delegatee}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.tertiary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              if (subTaskCount > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 2,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$doneCount/$subTaskCount',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
