import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'todo.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('todos.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    if (kIsWeb) {
      final factory = databaseFactoryFfiWeb;
      return await factory.openDatabase(
        'todos.db',
        options: OpenDatabaseOptions(version: 1, onCreate: _createDB),
      );
    }
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE todos (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      title TEXT NOT NULL,
      category TEXT NOT NULL,
      isDone INTEGER NOT NULL,
      tags TEXT NOT NULL,
      note TEXT,
      dueDate TEXT,
      priority TEXT NOT NULL,
      url TEXT,
      repeatPattern TEXT NOT NULL,
      lastCompletedDate TEXT,
      subTasks TEXT NOT NULL
    )
    ''');

    // Migration from SharedPreferences
    await _migrateFromSharedPreferences(db);
  }

  Future<void> _migrateFromSharedPreferences(Database db) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('todos');
      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        for (var json in jsonList) {
          final todo = Todo.fromJson(json);
          await db.insert('todos', {
            'title': todo.title,
            'category': todo.category.name,
            'isDone': todo.isDone ? 1 : 0,
            'tags': jsonEncode(todo.tags),
            'note': todo.note,
            'dueDate': todo.dueDate?.toIso8601String(),
            'priority': todo.priority.name,
            'url': todo.url,
            'repeatPattern': todo.repeatPattern.name,
            'lastCompletedDate': todo.lastCompletedDate?.toIso8601String(),
            'subTasks': jsonEncode(
              todo.subTasks.map((e) => e.toJson()).toList(),
            ),
          });
        }
        // Optional: clear SharedPreferences or mark as migrated
      }
    } catch (e) {
      print('Migration error: $e');
    }
  }

  Future<List<Todo>> readAllTodos() async {
    final db = await instance.database;
    final result = await db.query('todos');

    return result.map((json) {
      return Todo(
        id: json['id'] as int?,
        title: json['title'] as String,
        category: GtdCategory.values.firstWhere(
          (e) => e.name == json['category'],
          orElse: () => GtdCategory.inbox,
        ),
        isDone: (json['isDone'] as int) == 1,
        tags: json['tags'] != null
            ? List<String>.from(jsonDecode(json['tags'] as String))
            : [],
        note: json['note'] as String?,
        dueDate: json['dueDate'] != null
            ? DateTime.parse(json['dueDate'] as String)
            : null,
        priority: Priority.values.firstWhere(
          (e) => e.name == json['priority'],
          orElse: () => Priority.none,
        ),
        url: json['url'] as String?,
        repeatPattern: RepeatPattern.values.firstWhere(
          (e) => e.name == json['repeatPattern'],
          orElse: () => RepeatPattern.none,
        ),
        lastCompletedDate: json['lastCompletedDate'] != null
            ? DateTime.parse(json['lastCompletedDate'] as String)
            : null,
        subTasks: json['subTasks'] != null
            ? (jsonDecode(json['subTasks'] as String) as List)
                  .map((e) => SubTask.fromJson(e))
                  .toList()
            : [],
      );
    }).toList();
  }

  Future<int> create(Todo todo) async {
    final db = await instance.database;
    final id = await db.insert('todos', {
      'title': todo.title,
      'category': todo.category.name,
      'isDone': todo.isDone ? 1 : 0,
      'tags': jsonEncode(todo.tags),
      'note': todo.note,
      'dueDate': todo.dueDate?.toIso8601String(),
      'priority': todo.priority.name,
      'url': todo.url,
      'repeatPattern': todo.repeatPattern.name,
      'lastCompletedDate': todo.lastCompletedDate?.toIso8601String(),
      'subTasks': jsonEncode(todo.subTasks.map((e) => e.toJson()).toList()),
    });
    return id;
  }

  Future<int> update(Todo todo) async {
    final db = await instance.database;
    return db.update(
      'todos',
      {
        'title': todo.title,
        'category': todo.category.name,
        'isDone': todo.isDone ? 1 : 0,
        'tags': jsonEncode(todo.tags),
        'note': todo.note,
        'dueDate': todo.dueDate?.toIso8601String(),
        'priority': todo.priority.name,
        'url': todo.url,
        'repeatPattern': todo.repeatPattern.name,
        'lastCompletedDate': todo.lastCompletedDate?.toIso8601String(),
        'subTasks': jsonEncode(todo.subTasks.map((e) => e.toJson()).toList()),
      },
      where: 'id = ?',
      whereArgs: [todo.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete('todos', where: 'id = ?', whereArgs: [id]);
  }

  // Backup/Restore utilities
  Future<String> getDatabasePath() async {
    final dbPath = await getDatabasesPath();
    return join(dbPath, 'todos.db');
  }

  Future<void> restoreDatabase(String sourcePath) async {
    final dbPath = await getDatabasePath();
    // Close current connection
    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    // Copy file
    // NOTE: User needs to implement file copying here or calls logic in UI.
    // This helper could just expose the path or closing logic.
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
    _database = null;
  }
}
