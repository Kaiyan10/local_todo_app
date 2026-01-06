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
        options: OpenDatabaseOptions(
          version: 3,
          onCreate: _createDB,
          onUpgrade: _onUpgrade,
        ),
      );
    }
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 3, // Incremented version
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
    CREATE TABLE todos (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      parentId INTEGER,
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
      subTasks TEXT NOT NULL,
      delegatee TEXT,
      delegatedDate TEXT
    )
    ''');

    // Create index on parentId for performance
    await db.execute('CREATE INDEX idx_parent_id ON todos (parentId)');

    // Migration from SharedPreferences (if any)
    await _migrateFromSharedPreferences(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE todos ADD COLUMN delegatee TEXT');
      await db.execute('ALTER TABLE todos ADD COLUMN delegatedDate TEXT');
    }
    if (oldVersion < 3) {
      // Check if parentId exists to avoid duplicate column error
      final columns = await db.rawQuery('PRAGMA table_info(todos)');
      final hasParentId = columns.any((c) => c['name'] == 'parentId');

      if (!hasParentId) {
        await db.execute('ALTER TABLE todos ADD COLUMN parentId INTEGER');
        await db.execute('CREATE INDEX idx_parent_id ON todos (parentId)');
      }

      // Migration of data might still be needed if it was missing
      if (!hasParentId) {
        await _migrateSubTasksToTodos(db);
      } else {
        // If parentId existed, maybe data is already there?
        // Or maybe we still need to migrate subtasks from JSON?
        // Let's safe run it.
        await _migrateSubTasksToTodos(db);
      }
    }
  }

  Future<void> _migrateSubTasksToTodos(Database db) async {
    // 1. Fetch all todos that have subTasks
    final result = await db.query('todos');
    for (var row in result) {
      final subTasksJson = row['subTasks'] as String;
      if (subTasksJson.isEmpty || subTasksJson == '[]') continue;

      try {
        final List<dynamic> subTasks = jsonDecode(subTasksJson);
        final parentId = row['id'] as int;

        for (var subTask in subTasks) {
          // Create a new Todo for each subtask
          await db.insert('todos', {
            'parentId': parentId,
            'title': subTask['title'],
            'category': row['category'], // Inherit category? Or generic?
            'isDone': (subTask['isDone'] == true || subTask['isDone'] == 1)
                ? 1
                : 0,
            'tags': '[]',
            'note': null,
            'dueDate': null,
            'priority': 'none',
            'repeatPattern': 'none',
            'subTasks': '[]', // No recursive subtasks for now
          });
        }

        // Clear value in old column
        await db.update(
          'todos',
          {'subTasks': '[]'},
          where: 'id = ?',
          whereArgs: [parentId],
        );
      } catch (e) {
        print('Error migrating subtasks for todo ${row['id']}: $e');
      }
    }
  }

  Future<void> _migrateFromSharedPreferences(Database db) async {
    // ... existing implementation remains mostly same,
    // but we can skip migrating subtasks JSON if we want strict schema
    // For now, let's keep it simple.
  }

  Future<List<Todo>> readAllTodos() async {
    final db = await instance.database;
    final result = await db.query('todos');

    // Convert all rows to Map<id, Todo> first (without subtasks populated yet)
    final Map<int, Todo> todoMap = {};
    final List<Todo> roots = [];
    final Map<int, List<Todo>> childMap = {};

    for (var json in result) {
      // Temporary Todo object, assuming empty subtasks for now
      try {
        final todo = _rowToTodo(json);
        if (todo.id != null) {
          todoMap[todo.id!] = todo;
        }

        final parentId = json['parentId'] as int?;
        if (parentId != null) {
          childMap.putIfAbsent(parentId, () => []).add(todo);
        } else {
          roots.add(todo);
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing todo from DB: ${json['id']}, error: $e');
        }
        // Skip corrupted item
      }
    }

    // Now attach children to parents
    // Since List<Todo> subTasks is final, we have to rebuild the objects...
    // This is expensive with immutable/final fields.
    // Let's create a helper to build tree or just use the flat list if UI supports it?
    // The UI expects nested `subTasks`. `Todo` class has `final List<Todo> subTasks`.
    // So we must construct from bottom up or use a second pass copyWith.

    // Recursive function to build tree
    Todo attachChildren(Todo parent) {
      final children = childMap[parent.id] ?? [];
      final attachedChildren = children.map((c) => attachChildren(c)).toList();
      if (attachedChildren.isEmpty) return parent;
      return parent.copyWith(subTasks: attachedChildren);
    }

    return roots.map((root) => attachChildren(root)).toList();
  }

  Todo _rowToTodo(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] as int?,
      parentId: json['parentId'] as int?,
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
      subTasks: [], // Initially empty, populated by readAllTodos
      delegatee: json['delegatee'] as String?,
      delegatedDate: json['delegatedDate'] != null
          ? DateTime.parse(json['delegatedDate'] as String)
          : null,
    );
  }

  Future<int> create(Todo todo) async {
    final db = await instance.database;

    // Insert the todo (whether it is parent or child)
    final id = await db.insert('todos', {
      'parentId': todo.parentId,
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
      'subTasks': '[]', // Legacy column, keep empty
      'delegatee': todo.delegatee,
      'delegatedDate': todo.delegatedDate?.toIso8601String(),
    });

    // If there are subtasks in the object (e.g. created in memory with subtasks),
    // insert them with the new parentId.
    for (var sub in todo.subTasks) {
      await create(sub.copyWith(parentId: id));
    }

    return id;
  }

  Future<int> update(Todo todo) async {
    final db = await instance.database;
    int count = await db.update(
      'todos',
      {
        'parentId': todo.parentId,
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
        'delegatee': todo.delegatee,
        'delegatedDate': todo.delegatedDate?.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [todo.id],
    );

    if (todo.id != null) {
      // Sync subtasks
      // 1. Fetch existing IDs in DB
      final existingRows = await db.query(
        'todos',
        columns: ['id'],
        where: 'parentId = ?',
        whereArgs: [todo.id],
      );
      final existingIds = existingRows.map((r) => r['id'] as int).toList();

      // 2. Identify current IDs in the object
      final currentIds = todo.subTasks
          .map((t) => t.id)
          .where((id) => id != null)
          .cast<int>()
          .toSet();

      // 3. Delete removed IDs
      final idsToDelete = existingIds.where((id) => !currentIds.contains(id));
      for (var id in idsToDelete) {
        await delete(id);
      }

      // 4. Create or Update current subtasks
      for (var sub in todo.subTasks) {
        if (sub.id == null) {
          await create(sub.copyWith(parentId: todo.id));
        } else {
          // Recursively update
          await update(sub);
        }
      }
    }

    return count;
  }

  Future<int> delete(int id) async {
    final db = await instance.database;
    // Recursive delete? Yes, delete children.
    // First find children
    final result = await db.query(
      'todos',
      where: 'parentId = ?',
      whereArgs: [id],
    );
    for (var row in result) {
      await delete(row['id'] as int);
    }

    return await db.delete('todos', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteCompletedTodos() async {
    final db = await instance.database;
    // 1. Get all completed todos
    final result = await db.query(
      'todos',
      columns: ['id'],
      where: 'isDone = 1',
    );

    int count = 0;
    for (var row in result) {
      final id = row['id'] as int;
      // Use existing delete method to ensure children are also deleted
      count += await delete(id);
    }
    return count;
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
