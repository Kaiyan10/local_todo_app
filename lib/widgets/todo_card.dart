import 'package:flutter/material.dart';
import 'package:flutter_todo/data/todo.dart';
import 'package:intl/intl.dart';

final DateFormat _dateFormat = DateFormat('yyyy/MM/dd');

class TodoCard extends StatelessWidget {
  const TodoCard({
    super.key,
    required this.todo,
    required this.onEdit,
    required this.onCheckboxChanged,
  });

  final Todo todo;
  final VoidCallback onEdit;
  final ValueChanged<bool?> onCheckboxChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: ListTile(
        title: Text(todo.title),
        subtitle: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (todo.note != null)
              Text(
                todo.note!,
                style: const TextStyle(color: Colors.grey),
                maxLines: 3,
              ),
            Row(
              children: [
                if (todo.dueDate != null)
                  Text(
                    _dateFormat.format(todo.dueDate!),
                    style: const TextStyle(color: Colors.black),
                  ),
                if (todo.repeatPattern != RepeatPattern.none) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.repeat, size: 16, color: Colors.grey),
                  Text(
                    todo.repeatPattern.displayName,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
                const SizedBox(width: 8),
                if (todo.priority != Priority.none) todo.priority.badge!,
                if (todo.subTasks.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.checklist, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${todo.subTasks.where((st) => st.isDone).length}/${todo.subTasks.length}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: onEdit,
          style: IconButton.styleFrom(foregroundColor: Colors.grey),
        ),
        leading: Checkbox(
          shape: const CircleBorder(),
          value: todo.isDone,
          onChanged: onCheckboxChanged,
        ),
      ),
    );
  }
}
