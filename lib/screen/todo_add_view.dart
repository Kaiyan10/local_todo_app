import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/todo.dart';

class TodoAddView extends StatefulWidget {
  const TodoAddView({super.key, this.todo});

  final Todo? todo;

  @override
  State<TodoAddView> createState() => _TodoAddViewState();
}

class _TodoAddViewState extends State<TodoAddView> {
  final _textController = TextEditingController();
  final _tagsController = TextEditingController();
  final _urlController = TextEditingController();
  final _noteController = TextEditingController();
  final _dueDateController = TextEditingController();
  Priority _priority = Priority.none;
  GtdCategory _category = GtdCategory.inbox;
  RepeatPattern _repeatPattern = RepeatPattern.none;
  DateTime? _dueDate;
  List<SubTask> _subTasks = [];
  final _subTaskController = TextEditingController();

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
      _urlController.text = t.url ?? '';
      _noteController.text = t.note ?? '';
      _subTasks = List.from(t.subTasks);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _tagsController.dispose();
    _urlController.dispose();
    _noteController.dispose();
    _dueDateController.dispose();
    _subTaskController.dispose();
    super.dispose();
  }

  void _save() {
    if (_textController.text.trim().isNotEmpty) {
      final newTodo = Todo(
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
        url: _urlController.text.trim().isEmpty
            ? null
            : _urlController.text.trim(),
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        isDone: widget.todo?.isDone ?? false,
        subTasks: _subTasks,
      );
      Navigator.pop(context, newTodo);
    }
  }

  void _addSubTask() {
    final text = _subTaskController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _subTasks.add(SubTask(title: text));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.todo == null ? 'Add Task' : 'Edit Task'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  labelText: 'タスク名',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              // Category
              DropdownButtonFormField<GtdCategory>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'カテゴリ',
                  border: OutlineInputBorder(),
                ),
                items: GtdCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _category = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              // Priority
              DropdownButtonFormField<Priority>(
                value: _priority,
                decoration: const InputDecoration(
                  labelText: '優先度',
                  border: OutlineInputBorder(),
                ),
                items: Priority.values.map((priority) {
                  return DropdownMenuItem(
                    value: priority,
                    child: Text(priority.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _priority = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              // Due Date
              TextFormField(
                controller: _dueDateController,
                readOnly: true,
                decoration: InputDecoration(
                  labelText: '期限日',
                  border: const OutlineInputBorder(),
                  suffixIcon: _dueDate != null
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _dueDate = null;
                              _dueDateController.clear();
                            });
                          },
                        )
                      : IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: _pickDate,
                        ),
                ),
                onTap: _pickDate,
              ),
              const SizedBox(height: 16),
              // Repeat Pattern
              DropdownButtonFormField<RepeatPattern>(
                value: _repeatPattern,
                decoration: const InputDecoration(
                  labelText: '繰り返し',
                  border: OutlineInputBorder(),
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
              if (_repeatPattern != RepeatPattern.none && _dueDate == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    '※ 繰り返し設定には期限日（開始日）の設定が必要です',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              // Subtasks
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'サブタスク',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (_subTasks.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _subTasks.length,
                      itemBuilder: (context, index) {
                        final subTask = _subTasks[index];
                        return Row(
                          children: [
                            Checkbox(
                              value: subTask.isDone,
                              onChanged: (val) {
                                setState(() {
                                  subTask.isDone = val ?? false;
                                });
                              },
                            ),
                            Expanded(child: Text(subTask.title)),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setState(() {
                                  _subTasks.removeAt(index);
                                });
                              },
                            ),
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
                            isDense: true,
                          ),
                          onSubmitted: (_) => _addSubTask(),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: _addSubTask,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Tags
              TextField(
                controller: _tagsController,
                decoration: const InputDecoration(
                  labelText: 'Tags (comma separated)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // URL
              TextField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'URL',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              // Note
              TextField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: Text(widget.todo == null ? 'Add' : 'Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
