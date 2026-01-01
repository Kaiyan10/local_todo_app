import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';
import '../data/todo.dart';
import '../data/csv_service.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key, required this.todos, required this.onImport});

  final List<Todo> todos;
  final Function(List<Todo>) onImport;

  @override
  Widget build(BuildContext context) {
    final csvService = CsvService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('設定'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SettingsList(
        sections: [
          SettingsSection(
            title: const Text('データ'),
            tiles: <SettingsTile>[
              SettingsTile.navigation(
                leading: const Icon(Icons.download),
                title: const Text('CSVエクスポート'),
                onPressed: (context) async {
                  await csvService.exportToCsv(todos);
                },
              ),
              SettingsTile.navigation(
                leading: const Icon(Icons.upload),
                title: const Text('CSVインポート'),
                onPressed: (context) async {
                  FilePickerResult? result = await FilePicker.platform
                      .pickFiles(
                        type: FileType.custom,
                        allowedExtensions: ['csv'],
                      );

                  if (result != null) {
                    final file = result.files.single;
                    final newTodos = await csvService.importFromCsv(file);
                    onImport(newTodos);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${newTodos.length} 件のタスクをインポートしました'),
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
          SettingsSection(
            title: const Text('一般'),
            tiles: <SettingsTile>[
              SettingsTile.navigation(
                leading: const Icon(Icons.language),
                title: const Text('言語'),
                value: const Text('日本語'),
              ),
              SettingsTile.switchTile(
                onToggle: (value) {},
                initialValue: true,
                leading: const Icon(Icons.format_paint),
                title: const Text('テーマ'),
              ),
            ],
          ),
          SettingsSection(
            title: const Text('アカウント'),
            tiles: <SettingsTile>[
              SettingsTile.navigation(
                leading: const Icon(Icons.logout),
                title: const Text('ログアウト'),
                onPressed: (context) {
                  // TODO: Implement logout
                },
              ),
            ],
          ),
          SettingsSection(
            title: const Text('アプリについて'),
            tiles: <SettingsTile>[
              SettingsTile.navigation(
                leading: const Icon(Icons.info),
                title: const Text('バージョン'),
                value: const Text('1.0.0'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
