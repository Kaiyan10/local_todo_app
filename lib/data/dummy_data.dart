import 'todo.dart';

final List<Todo> dummyTodos = [
  Todo(title: '牛乳を買う', categoryId: 'nextAction'),
  Todo(title: '犬の散歩', categoryId: 'nextAction'),
  Todo(title: 'Flutterの勉強', categoryId: 'project', note: 'UIのリファクタリング'),
  Todo(title: '読書', categoryId: 'someday'),
  Todo(
    title: 'チームミーティング',
    categoryId: 'nextAction',
    priority: Priority.high,
  ),
  Todo(title: '掃除'), // Default Inbox
];
