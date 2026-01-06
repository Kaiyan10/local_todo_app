class Category {
  final String id;
  final String name;
  final bool isSystem;

  const Category({
    required this.id,
    required this.name,
    this.isSystem = false,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'isSystem': isSystem,
    };
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      isSystem: json['isSystem'] as bool? ?? false,
    );
  }
}

class SystemCategories {
  static const String inbox = 'inbox';
  static const String nextAction = 'nextAction';
  static const String project = 'project';
  static const String waitingFor = 'waitingFor';
  static const String someday = 'someday';
  static const String reference = 'reference';

  static const List<Category> initialCategories = [
    Category(id: inbox, name: 'Inbox', isSystem: true),
    Category(id: nextAction, name: 'Next Action', isSystem: true),
    Category(id: project, name: 'Project', isSystem: true),
    Category(id: waitingFor, name: 'Waiting For', isSystem: true),
    Category(id: someday, name: 'Someday/Maybe', isSystem: true),
    Category(id: reference, name: 'Reference', isSystem: true),
  ];
}
