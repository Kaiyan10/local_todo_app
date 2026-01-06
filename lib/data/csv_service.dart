import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as html;
import 'package:universal_io/io.dart' as io;

import 'todo.dart';
import 'settings_service.dart';

class CsvService {
  String generateCsvContent(List<Todo> todos) {
    final List<List<dynamic>> rows = [];
    // Header
    rows.add([
      'title',
      'category',
      'isDone',
      'priority',
      'dueDate',
      'note',
      'tags',
      'url',
    ]);

    for (var todo in todos) {
      rows.add([
        todo.title,
        SettingsService().getCategoryName(todo.categoryId),
        todo.isDone ? 1 : 0,
        todo.priority.name,
        todo.dueDate?.toIso8601String() ?? '',
        todo.note ?? '',
        todo.tags.join(';'),
        todo.url ?? '',
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  Future<void> exportToCsv(List<Todo> todos) async {
    final csv = generateCsvContent(todos);

    if (kIsWeb) {
      // Export for Web: Download file
      final bytes = utf8.encode(csv);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "todos_export.csv")
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // Export for Mobile/Desktop: Share file
      final directory = await getTemporaryDirectory();
      final path = "${directory.path}/todos_export.csv";
      final file = io.File(path);
      await file.writeAsString(csv);
      await Share.shareXFiles([XFile(path)], text: 'Todo List Export');
    }
  }

  List<Todo> parseCsvContent(String input) {
    try {
      final eol = input.contains('\r\n') ? '\r\n' : '\n';
      final fields = CsvToListConverter(eol: eol).convert(input);

      if (fields.isEmpty) return [];

      // Remove header if present (Simple check: if first row first col is 'title')
      var rows = fields;
      if (rows.isNotEmpty &&
          rows.first.isNotEmpty &&
          rows.first[0] == 'title') {
        rows = rows.sublist(1);
      }

      return rows
          .map((row) {
            // Safety check for length
            if (row.length < 1) return null;

            final title = row[0].toString();

            final categoryName = row.length > 1 ? row[1].toString() : 'inbox';
            // Simple import strategy: find matching name, else default to inbox (or create new?)
            // For now, let's map back to ID if it matches a known category name (case insensitive?)
            // Actually, CSV export exported DISPLAY NAME.
            // So we need to find category ID by display name.
            final categoryId = SettingsService().categories.firstWhere(
              (c) => c.name == categoryName,
              orElse: () => SettingsService().categories.firstWhere((c) => c.id == 'inbox'),
            ).id;

            final isDoneVal = row.length > 2 ? row[2] : 0;
            final isDone =
                (isDoneVal.toString() == '1' ||
                isDoneVal.toString().toLowerCase() == 'true');

            final priorityName = row.length > 3 ? row[3].toString() : 'none';
            final priority = Priority.values.firstWhere(
              (e) => e.name == priorityName,
              orElse: () => Priority.none,
            );

            DateTime? dueDate;
            if (row.length > 4 && row[4].toString().isNotEmpty) {
              dueDate = DateTime.tryParse(row[4].toString());
            }

            final note = row.length > 5 ? row[5].toString() : null;

            List<String> tags = [];
            if (row.length > 6 && row[6].toString().isNotEmpty) {
              tags = row[6].toString().split(';');
            }

            final url = row.length > 7 ? row[7].toString() : null;

            return Todo(
              title: title,
              categoryId: categoryId,
              isDone: isDone,
              priority: priority,
              dueDate: dueDate,
              note: note,
              tags: tags,
              url: url,
            );
          })
          .whereType<Todo>()
          .toList();
    } catch (e) {
      print('Error parsing CSV: $e');
      return [];
    }
  }

  Future<List<Todo>> importFromCsv(PlatformFile file) async {
    try {
      String input;
      if (kIsWeb) {
        // On Web, use bytes
        if (file.bytes == null) throw Exception("No data in file");
        input = utf8.decode(file.bytes!);
      } else {
        // On Native, use path
        if (file.path == null) throw Exception("No file path");
        input = await io.File(file.path!).readAsString();
      }

      return parseCsvContent(input);
    } catch (e) {
      print('Error reading CSV file details: $e');
      return [];
    }
  }
}
