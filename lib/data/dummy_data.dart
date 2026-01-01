import 'todo.dart';

final List<Todo> dummyTodos = [
  Todo(title: '牛乳を買う', category: GtdCategory.nextAction),
  Todo(title: '犬の散歩', category: GtdCategory.nextAction),
  Todo(title: 'Flutterの勉強', category: GtdCategory.project, note: 'UIのリファクタリング'),
  Todo(title: '読書', category: GtdCategory.someday),
  Todo(
    title: 'チームミーティング',
    category: GtdCategory.nextAction,
    priority: Priority.high,
  ),
  Todo(title: '掃除'), // Default Inbox
];
