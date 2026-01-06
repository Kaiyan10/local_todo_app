import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../data/todo.dart';
import '../data/settings_service.dart';

class TodoAddView extends StatefulWidget {
  const TodoAddView({super.key, this.todo});

  final Todo? todo;

  @override
  State<TodoAddView> createState() => _TodoAddViewState();
}

class _TodoAddViewState extends State<TodoAddView> {
  final _textController = TextEditingController();
  final _tagsController = TextEditingController();
  final _noteController = TextEditingController();
  final _dueDateController = TextEditingController();
  Priority _priority = Priority.none;
  GtdCategory _category = GtdCategory.inbox;
  RepeatPattern _repeatPattern = RepeatPattern.none;
  DateTime? _dueDate;
  List<SubTaskWrapper> _subTasks = [];
  final _subTaskController = TextEditingController();
  final _delegateeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.todo != null) {
      final t = widget.todo!;
      _textController.text = t.title;
      _category = t.category;
      _priority = t.priority;
      _repeatPattern = t.repeatPattern;
      _dueDate = t.dueDate;
      if (_dueDate != null) {
        _dueDateController.text = DateFormat.yMd().format(_dueDate!);
      }
      _tagsController.text = t.tags.join(', ');
      _noteController.text = t.note ?? '';
      _subTasks = t.subTasks.map((e) => SubTaskWrapper(e)).toList();
      _delegateeController.text = t.delegatee ?? '';
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _tagsController.dispose();
    _noteController.dispose();
    _dueDateController.dispose();
    _subTaskController.dispose();
    _delegateeController.dispose();
    super.dispose();
  }

  void _save() {
    if (_textController.text.trim().isNotEmpty) {
      final newTodo = Todo(
        id: widget.todo?.id, // Keep ID for updates
        parentId: widget.todo?.parentId, // Keep parentId for subtasks
        title: _textController.text.trim(),
        category: _category,
        priority: _priority,
        dueDate: _dueDate,
        repeatPattern: _repeatPattern,
        tags: _tagsController.text
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList(),
        url: widget.todo?.url, // Keep existing URL if editing, or null for new
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        isDone: widget.todo?.isDone ?? false,
        subTasks: _subTasks.map((e) => e.todo).toList(),
        delegatee:
            _category == GtdCategory.waitingFor &&
                _delegateeController.text.trim().isNotEmpty
            ? _delegateeController.text.trim()
            : null,
      );
      Navigator.pop(context, newTodo);
    }
  }

  void _addSubTask() {
    final text = _subTaskController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _subTasks.add(
          SubTaskWrapper(
            Todo(
              title: text,
              category: _category,
              priority: _priority,
              tags: _tagsController.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList(),
            ),
          ),
        ); // Create Todo instead of SubTask
        _subTaskController.clear();
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
        _dueDateController.text = DateFormat.yMd().format(picked);
      });
    }
  }

  void _toggleTag(String tag) {
    final currentTags = _tagsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (currentTags.contains(tag)) {
      currentTags.remove(tag);
    } else {
      currentTags.add(tag);
    }

    setState(() {
      _tagsController.text = currentTags.join(', ');
    });
  }

  void _setDate(DateTime date) {
    setState(() {
      _dueDate = date;
      _dueDateController.text = DateFormat.yMd().format(date);
    });
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter, control: true): _save,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: AppBar(
            // Title removed for modern look
            scrolledUnderElevation: 0,
          ),
      floatingActionButton: FloatingActionButton(
        onPressed: _save,
        child: const Icon(Icons.check),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 32),
              _buildCategorySection(),
              const SizedBox(height: 24),
              _buildScheduleSection(),
              const SizedBox(height: 24),
              _buildDetailsSection(),
              const SizedBox(height: 80), // Space for FAB
            ],
          ),
        ),
      ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return TextField(
      controller: _textController,
      style: Theme.of(
        context,
      ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        hintText: 'タスク名を入力',
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.grey.withOpacity(0.5)),
      ),
      autofocus: widget.todo == null, // Autofocus only on new task
      maxLines: null,
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'カテゴリ',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: GtdCategory.values.map((category) {
            final isSelected = _category == category;
            return ChoiceChip(
              label: Text(category.displayName),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _category = category;
                  });
                }
              },
            );
          }).toList(),
        ),
        if (_category == GtdCategory.waitingFor) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _delegateeController,
            decoration: const InputDecoration(
              labelText: '担当者 (Delegatee)',
              border: OutlineInputBorder(),
              helperText: '誰からの返信待ちですか？',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'スケジュール & 優先度',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context).dividerColor.withOpacity(0.1),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Priority
                Row(
                  children: [
                    const Icon(Icons.flag_outlined, color: Colors.grey),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SegmentedButton<Priority>(
                        segments: Priority.values.map((p) {
                          return ButtonSegment<Priority>(
                            value: p,
                            label: Text(p.displayName),
                          );
                        }).toList(),
                        selected: {_priority},
                        onSelectionChanged: (Set<Priority> newSelection) {
                          setState(() {
                            _priority = newSelection.first;
                          });
                        },
                        style: ButtonStyle(
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Due Date
                InkWell(
                  onTap: _pickDate,
                  child: Row(
                    children: [
                      const Icon(Icons.event_outlined, color: Colors.grey),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _dueDate != null
                              ? DateFormat.yMd().format(_dueDate!)
                              : '期限日を設定',
                          style: TextStyle(
                            color: _dueDate != null
                                ? Theme.of(context).textTheme.bodyLarge?.color
                                : Colors.grey,
                          ),
                        ),
                      ),
                      if (_dueDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () {
                            setState(() {
                              _dueDate = null;
                              _dueDateController.clear();
                            });
                          },
                          constraints: const BoxConstraints(),
                          padding: EdgeInsets.zero,
                        ),
                    ],
                  ),
                ),
                if (_dueDate != null) ...[
                  const SizedBox(height: 8),
                  // Repeat Pattern
                  Row(
                    children: [
                      const Icon(Icons.repeat, color: Colors.grey),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<RepeatPattern>(
                          value: _repeatPattern,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          items: RepeatPattern.values.map((pattern) {
                            return DropdownMenuItem(
                              value: pattern,
                              child: Text(pattern.displayName),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _repeatPattern = value;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                // Quick Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ActionChip(
                        label: const Text('今日'),
                        onPressed: () => _setDate(DateTime.now()),
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        label: const Text('明日'),
                        onPressed: () => _setDate(
                          DateTime.now().add(const Duration(days: 1)),
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        label: const Text('来週'),
                        onPressed: () => _setDate(
                          DateTime.now().add(const Duration(days: 7)),
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsSection() {
    return ExpansionTile(
      title: Text(
        '詳細 (サブタスク, タグ, メモ)',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      initiallyExpanded:
          _subTasks.isNotEmpty ||
          _tagsController.text.isNotEmpty ||
          _noteController.text.isNotEmpty,
      children: [
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Theme.of(context).dividerColor.withOpacity(0.1),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Subtasks
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.checklist, color: Colors.grey),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_subTasks.isNotEmpty)
                            ReorderableListView.builder(
                              buildDefaultDragHandles: false,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _subTasks.length,
                              onReorder: (int oldIndex, int newIndex) {
                                setState(() {
                                  if (oldIndex < newIndex) {
                                    newIndex -= 1;
                                  }
                                  final item = _subTasks.removeAt(oldIndex);
                                  _subTasks.insert(newIndex, item);
                                });
                              },
                              itemBuilder: (context, index) {
                                final wrapper = _subTasks[index];
                                final subTask = wrapper.todo;
                                return Column(
                                  key: wrapper.key,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      dense: true,
                                      contentPadding: EdgeInsets.zero,
                                      leading: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ReorderableDragStartListener(
                                            index: index,
                                            child: const Padding(
                                              padding: EdgeInsets.only(
                                                right: 8.0,
                                              ),
                                              child: Icon(
                                                Icons.drag_handle,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ),
                                          Checkbox(
                                            value: subTask.isDone,
                                            onChanged: (val) {
                                              setState(() {
                                                wrapper.todo = subTask.copyWith(
                                                  isDone: val ?? false,
                                                );
                                              });
                                            },
                                            visualDensity:
                                                VisualDensity.compact,
                                          ),
                                        ],
                                      ),
                                      title: Text(
                                        subTask.title,
                                        style: TextStyle(
                                          decoration: subTask.isDone
                                              ? TextDecoration.lineThrough
                                              : null,
                                          color: subTask.isDone
                                              ? Colors.grey
                                              : null,
                                        ),
                                      ),
                                      subtitle: (subTask.dueDate != null ||
                                              subTask.priority != Priority.none)
                                          ? Padding(
                                              padding: const EdgeInsets.only(
                                                  top: 4.0),
                                              child: Row(
                                                children: [
                                                  if (subTask.priority !=
                                                      Priority.none) ...[
                                                    Container(
                                                      margin:
                                                          const EdgeInsets.only(
                                                              right: 8),
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 6,
                                                          vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            _getPriorityColor(
                                                                    subTask
                                                                        .priority)
                                                                .withOpacity(
                                                                    0.2),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(4),
                                                      ),
                                                      child: Text(
                                                        subTask.priority
                                                            .displayName,
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          color:
                                                              _getPriorityColor(
                                                                  subTask
                                                                      .priority),
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                  if (subTask.dueDate !=
                                                      null) ...[
                                                    Icon(
                                                      Icons.calendar_today,
                                                      size: 12,
                                                      color: subTask.dueDate!
                                                                  .isBefore(DateTime
                                                                      .now()) &&
                                                              !subTask.isDone
                                                          ? Colors.red
                                                          : Colors.grey,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      DateFormat.yMd().format(
                                                          subTask.dueDate!),
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: subTask.dueDate!
                                                                    .isBefore(DateTime
                                                                        .now()) &&
                                                                !subTask.isDone
                                                            ? Colors.red
                                                            : Colors.grey,
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            )
                                          : null,
                                      trailing: IconButton(
                                        icon: const Icon(Icons.close, size: 18),
                                        onPressed: () {
                                          setState(() {
                                            _subTasks.removeAt(index);
                                          });
                                        },
                                      ),
                                      onTap: () async {
                                        final updated =
                                            await Navigator.push<Todo>(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    TodoAddView(todo: subTask),
                                              ),
                                            );
                                        if (updated != null) {
                                          setState(() {
                                            wrapper.todo = updated;
                                          });
                                        }
                                      },
                                    ),
                                    const Divider(height: 1),
                                  ],
                                );
                              },
                            ),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _subTaskController,
                                  decoration: const InputDecoration(
                                    hintText: 'サブタスクを追加...',
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                  onSubmitted: (_) => _addSubTask(),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: _addSubTask,
                                color: Theme.of(context).primaryColor,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(),
                // Tags
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.label_outline, color: Colors.grey),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _tagsController,
                            decoration: const InputDecoration(
                              hintText: 'タグ (カンマ区切り)',
                              border: InputBorder.none,
                            ),
                          ),
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 4.0,
                            children: SettingsService().contexts.map((tag) {
                              final currentTags = _tagsController.text
                                  .split(',')
                                  .map((e) => e.trim())
                                  .toList();
                              final isSelected = currentTags.contains(tag);
                              return FilterChip(
                                label: Text(tag),
                                selected: isSelected,
                                onSelected: (_) => _toggleTag(tag),
                                visualDensity: VisualDensity.compact,
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(),
                // Note
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.notes, color: Colors.grey),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _noteController,
                        decoration: const InputDecoration(
                          hintText: 'メモを追加...',
                          border: InputBorder.none,
                        ),
                        maxLines: null,
                        minLines: 3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  Color _getPriorityColor(Priority priority) {
    switch (priority) {
      case Priority.high:
        return Colors.red;
      case Priority.medium:
        return Colors.orange;
      case Priority.low:
        return Colors.green;
      case Priority.none:
        return Colors.grey;
    }
  }
}

class SubTaskWrapper {
  final Key key;
  Todo todo;
  SubTaskWrapper(this.todo) : key = UniqueKey();
}
