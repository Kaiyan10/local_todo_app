import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:share_plus/share_plus.dart';
import '../data/todo.dart';
import '../data/csv_service.dart';
import '../data/database_helper.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({
    super.key,
    required this.todos,
    required this.onImport,
    required this.onReload,
  });

  final List<Todo> todos;
  final Function(List<Todo>) onImport;
  final VoidCallback onReload;

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
          if (!kIsWeb)
            SettingsSection(
              title: const Text('バックアップと復元（ローカル）'),
              tiles: [
                SettingsTile.navigation(
                  leading: const Icon(Icons.save),
                  title: const Text('バックアップ作成'),
                  description: const Text('現在のデータをファイルとして保存します'),
                  onPressed: (context) async {
                    try {
                      final dbPath = await DatabaseHelper.instance
                          .getDatabasePath();
                      final file = File(dbPath);
                      if (await file.exists()) {
                        // Share file
                        await Share.shareXFiles([
                          XFile(dbPath),
                        ], text: 'Todo Backup');
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('データベースが見つかりません')),
                          );
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('バックアップエラー: $e')),
                        );
                      }
                    }
                  },
                ),
                SettingsTile.navigation(
                  leading: const Icon(Icons.restore),
                  title: const Text('復元'),
                  description: const Text(
                    'バックアップファイルからデータを復元します\n※現在のデータは上書きされます',
                  ),
                  onPressed: (context) async {
                    // Confirmation dialog
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('復元の確認'),
                        content: const Text('現在のデータはすべて上書きされます。よろしいですか？'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('キャンセル'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('復元する'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed != true) return;

                    FilePickerResult? result = await FilePicker.platform
                        .pickFiles();
                    if (result != null && result.files.single.path != null) {
                      try {
                        final sourcePath = result.files.single.path!;
                        await DatabaseHelper.instance.close();

                        final dbPath = await DatabaseHelper.instance
                            .getDatabasePath();
                        await File(sourcePath).copy(dbPath);

                        // Reload data
                        onReload();

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('復元が完了しました')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('復元エラー: $e')));
                        }
                      }
                    }
                  },
                ),
              ],
            ),
          SettingsSection(
            title: const Text('データ (CSV)'),
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
                    // Ensure valid file via platform check if mostly web, but this is database approach.
                    // CSV Import adds to DB.
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
