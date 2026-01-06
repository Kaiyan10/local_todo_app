import 'package:flutter/material.dart';

class Todo {
  final int? id;
  final int? parentId; // Added parentId
  final String title;
  String categoryId;
  bool isDone;
  final List<String> tags;
  final String? note;
  DateTime? dueDate;
  Priority priority;
  final String? url;
  RepeatPattern repeatPattern;
  DateTime? lastCompletedDate;
  final List<Todo> subTasks; // Changed from List<SubTask>
  String? delegatee;
  DateTime? delegatedDate;

  Todo({
    this.id,
    this.parentId,
    required this.title,
    this.categoryId = 'inbox',
    this.isDone = false,
    this.tags = const [],
    this.note,
    this.dueDate,
    this.priority = Priority.none,
    this.url,
    this.repeatPattern = RepeatPattern.none,
    this.lastCompletedDate,
    this.subTasks = const [],
    this.delegatee,
    this.delegatedDate,
  });

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'],
      parentId: json['parentId'],
      title: json['title'],
      categoryId: json['category'] ?? 'inbox',
      isDone: json['isDone'] is int
          ? (json['isDone'] == 1)
          : (json['isDone'] ?? false), // Handle both int (DB) and bool (JSON)
      tags: List<String>.from(json['tags'] ?? []),
      note: json['note'],
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      priority: Priority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => Priority.none,
      ),
      url: json['url'],
      repeatPattern: RepeatPattern.values.firstWhere(
        (e) => e.name == (json['repeatPattern'] ?? 'none'),
        orElse: () => RepeatPattern.none,
      ),
      lastCompletedDate: json['lastCompletedDate'] != null
          ? DateTime.parse(json['lastCompletedDate'])
          : null,
      subTasks:
          (json['subTasks'] as List<dynamic>?)
              ?.map((e) => Todo.fromJson(e))
              .toList() ??
          [],
      delegatee: json['delegatee'],
      delegatedDate: json['delegatedDate'] != null
          ? DateTime.parse(json['delegatedDate'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parentId': parentId,
      'title': title,
      'category': categoryId,
      'isDone': isDone,
      'tags': tags,
      'note': note,
      'dueDate': dueDate?.toIso8601String(),
      'priority': priority.name,
      'url': url,
      'repeatPattern': repeatPattern.name,
      'lastCompletedDate': lastCompletedDate?.toIso8601String(),
      'subTasks': subTasks.map((e) => e.toJson()).toList(),
      'delegatee': delegatee,
      'delegatedDate': delegatedDate?.toIso8601String(),
    };
  }

  Todo copyWith({
    int? id,
    int? parentId,
    String? title,
    String? categoryId,
    bool? isDone,
    List<String>? tags,
    String? note,
    DateTime? dueDate,
    Priority? priority,
    String? url,
    RepeatPattern? repeatPattern,
    DateTime? lastCompletedDate,
    List<Todo>? subTasks,
    String? delegatee,
    DateTime? delegatedDate,
    bool resetDueDate = false,
    bool resetDelegatee = false,
  }) {
    return Todo(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      title: title ?? this.title,
      categoryId: categoryId ?? this.categoryId,
      isDone: isDone ?? this.isDone,
      tags: tags ?? this.tags,
      note: note ?? this.note,
      dueDate: resetDueDate ? null : (dueDate ?? this.dueDate),
      priority: priority ?? this.priority,
      url: url ?? this.url,
      repeatPattern: repeatPattern ?? this.repeatPattern,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      subTasks: subTasks ?? this.subTasks,
      delegatee: resetDelegatee ? null : (delegatee ?? this.delegatee),
      delegatedDate: delegatedDate ?? this.delegatedDate,
    );
  }
}

enum RepeatPattern {
  none,
  daily,
  weekly,
  monthly,
  yearly;

  String get displayName {
    switch (this) {
      case RepeatPattern.none:
        return '繰返しなし';
      case RepeatPattern.daily:
        return '毎日';
      case RepeatPattern.weekly:
        return '毎週';
      case RepeatPattern.monthly:
        return '毎月';
      case RepeatPattern.yearly:
        return '毎年';
    }
  }

  DateTime? nextDate(DateTime current) {
    switch (this) {
      case RepeatPattern.none:
        return null;
      case RepeatPattern.daily:
        return current.add(const Duration(days: 1));
      case RepeatPattern.weekly:
        return current.add(const Duration(days: 7));
      case RepeatPattern.monthly:
        // Simple implementation: Add a month.
        // For distinct handling (e.g. Jan 31 -> Feb 28), more complex logic needed.
        // Using straightforward approach for now.
        return DateTime(
          current.year,
          current.month + 1,
          current.day,
          current.hour,
          current.minute,
        );
      case RepeatPattern.yearly:
        return DateTime(
          current.year + 1,
          current.month,
          current.day,
          current.hour,
          current.minute,
        );
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
