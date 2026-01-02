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

  @override
  // Ideally, if subtasks exist, we want the card to be expandable.
  // Standard ExpansionTile forces a specific layout (leading, title, trailing).
  // Our TodoCard has custom layout.
  // We can use helper variable to track expansion if we build manually, but ExpansionTile is easier if we fit our content.
  // Let's try to fit our content into ExpansionTile's title/subtitle.
  // Issue: ExpansionTile trailing is usually the arrow. We have an edit button.
  // We can put the edit button in the title/subtitle or use empty trailing and put arrow elsewhere?
  // Or just put Edit button in the expanded area? No, we want quick access.
  // Let's keep Edit button as trailing. The ExpansionTile arrow can be hidden or replaced?
  // Actually, tapping the tile expands it.
  @override
  Widget build(BuildContext context) {
    // If no subtasks, return simple card (previous behavior)
    if (widget.todo.subTasks.isEmpty) {
      return _buildCardContent(context, expand: false);
    }

    return Card(
      child: Column(
        children: [
          _buildCardContent(context, expand: true),
          if (_isExpanded)
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
                  onLongPress: () {
                    // Show menu for promotion
                    // final RenderBox overlay =
                    //    Overlay.of(context).context.findRenderObject()
                    //        as RenderBox;
                    // We need position. Actually PopupMenuButton is easier if we can put it in the layout.
                    // But we are in a Row.
                  },
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subTask.title,
                              style: TextStyle(
                                decoration: subTask.isDone
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: subTask.isDone ? Colors.grey : null,
                                fontSize: 13,
                              ),
                            ),
                            if (subTask.dueDate != null)
                              Text(
                                _dateFormat.format(subTask.dueDate!),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: subTask.isDone
                                      ? Colors.grey
                                      : Colors.red,
                                ),
                              ),
                          ],
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
                              child: Text('タスクに昇格'),
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
            }).toList(),
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
      ),
    );
  }

  Widget _buildCardContent(BuildContext context, {required bool expand}) {
    final hasSubTasks = widget.todo.subTasks.isNotEmpty;
    // If not using custom expand, we wrap in Card if called directly
    // But here we use it inside Column or as root.
    // Ideally this returns the ListTile.

    // We need to return Card if call from build (isEmpty case).
    // Or just return the ListTile content and wrap it in Card in build?

    Widget content = ListTile(
      title: _buildTitle(),
      subtitle: _buildSubtitle(context),
      leading: Checkbox(
        shape: const CircleBorder(),
        value: widget.todo.isDone,
        onChanged: widget.onCheckboxChanged,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (expand && hasSubTasks)
            IconButton(
              icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
            ),
          IconButton(icon: const Icon(Icons.edit), onPressed: widget.onEdit),
        ],
      ),
      onTap: (expand && hasSubTasks)
          ? () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            }
          : null,
    );

    if (!expand) {
      // Wrap in Card if standalone
      return Card(child: content);
    }
    return content;
  }

  Widget _buildTitle() {
    return Text(widget.todo.title);
  }

  Widget _buildSubtitle(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.todo.note != null)
          Text(
            widget.todo.note!,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            maxLines: 3,
          ),
        Row(
          children: [
            if (widget.todo.dueDate != null)
              Text(_dateFormat.format(widget.todo.dueDate!)),
            if (widget.todo.repeatPattern != RepeatPattern.none) ...[
              const SizedBox(width: 4),
              const Icon(Icons.repeat, size: 16),
              Text(
                widget.todo.repeatPattern.displayName,
                style: const TextStyle(fontSize: 12),
              ),
            ],
            const SizedBox(width: 8),
            if (widget.todo.priority != Priority.none)
              widget.todo.priority.badge!,
          ],
        ),
        if (widget.todo.category == GtdCategory.waitingFor &&
            widget.todo.delegatee != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.person, size: 16, color: Colors.blueGrey),
              const SizedBox(width: 4),
              Text(
                '待ち: ${widget.todo.delegatee}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
            ],
          ),
        ],
        if (widget.todo.subTasks.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value:
                      widget.todo.subTasks.where((s) => s.isDone).length /
                      widget.todo.subTasks.length,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(widget.todo.subTasks.where((s) => s.isDone).length / widget.todo.subTasks.length * 100).toInt()}%',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.todo.subTasks.where((st) => st.isDone).length}/${widget.todo.subTasks.length} サブタスク完了',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ],
    );
  }
}
