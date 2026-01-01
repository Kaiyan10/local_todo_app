import 'package:flutter/material.dart';

class Todo {
  final String title;
  GtdCategory category;
  bool isDone;
  final List<String> tags;
  final String? note;
  DateTime? dueDate;
  Priority priority;
  final String? url;

  Todo({
    required this.title,
    this.category = GtdCategory.inbox,
    this.isDone = false,
    this.tags = const [],
    this.note,
    this.dueDate,
    this.priority = Priority.none,
    this.url,
  });

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      title: json['title'],
      category: GtdCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => GtdCategory.inbox,
      ),
      isDone: json['isDone'] ?? false,
      tags: List<String>.from(json['tags'] ?? []),
      note: json['note'],
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      priority: Priority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => Priority.none,
      ),
      url: json['url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'category': category.name,
      'isDone': isDone,
      'tags': tags,
      'note': note,
      'dueDate': dueDate?.toIso8601String(),
      'priority': priority.name,
      'url': url,
    };
  }
}

enum GtdCategory {
  inbox,
  nextAction,
  project,
  waitingFor,
  someday,
  reference;

  String get displayName {
    switch (this) {
      case GtdCategory.inbox:
        return 'Inbox';
      case GtdCategory.nextAction:
        return 'Next Action';
      case GtdCategory.project:
        return 'Project';
      case GtdCategory.waitingFor:
        return 'Waiting For';
      case GtdCategory.someday:
        return 'Someday/Maybe';
      case GtdCategory.reference:
        return 'Reference';
    }
  }
}

enum Priority {
  none,
  high,
  medium,
  low;

  String get displayName {
    switch (this) {
      case Priority.none:
        return 'None';
      case Priority.high:
        return 'High';
      case Priority.medium:
        return 'Medium';
      case Priority.low:
        return 'Low';
    }
  }

  Widget? get badge {
    switch (this) {
      case Priority.none:
        return null;
      case Priority.high:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.red),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            "高",
            style: TextStyle(color: Colors.red, fontSize: 12),
          ),
        );
      case Priority.medium:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.orange),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            "中",
            style: TextStyle(color: Colors.orange, fontSize: 12),
          ),
        );
      case Priority.low:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.green),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            "低",
            style: TextStyle(color: Colors.green, fontSize: 12),
          ),
        );
    }
  }
}
