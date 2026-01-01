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
                const SizedBox(width: 8),
                if (todo.priority != Priority.none) todo.priority.badge!,
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: onEdit,
          style: IconButton.styleFrom(foregroundColor: Colors.grey),
        ),
        leading: Checkbox(value: todo.isDone, onChanged: onCheckboxChanged),
      ),
    );
  }
}
