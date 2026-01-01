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
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    if (widget.todo != null) {
      final t = widget.todo!;
      _textController.text = t.title;
      _category = t.category;
      _priority = t.priority;
      _dueDate = t.dueDate;
      if (_dueDate != null) {
        _dueDateController.text = DateFormat.yMd().format(_dueDate!);
      }
      _tagsController.text = t.tags.join(', ');
      _urlController.text = t.url ?? '';
      _noteController.text = t.note ?? '';
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _tagsController.dispose();
    _urlController.dispose();
    _noteController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }

  void _save() {
    if (_textController.text.trim().isNotEmpty) {
      final newTodo = Todo(
        title: _textController.text.trim(),
        category: _category,
        priority: _priority,
        dueDate: _dueDate,
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
      );
      Navigator.pop(context, newTodo);
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
