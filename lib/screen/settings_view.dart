import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:share_plus/share_plus.dart';
import '../data/todo.dart';
import '../data/category_model.dart' as model;
import '../data/settings_service.dart';
import '../data/csv_service.dart';
import '../data/todo_repository.dart';
import '../data/database_helper.dart';
import '../widgets/settings_editors.dart';


class SettingsView extends StatelessWidget {
  const SettingsView({
    super.key,
    required this.todos,
    required this.onImport,
    required this.onReload,
    required this.onThemeChanged,
    required this.currentThemeMode,
  });

  final List<Todo> todos;
  final Function(List<Todo>) onImport;
  final VoidCallback onReload;
  final Function(ThemeMode) onThemeChanged;
  final ThemeMode currentThemeMode;

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
              SettingsTile.navigation(
                leading: const Icon(Icons.delete_forever),
                title: const Text('完了済みタスクを削除'),
                onPressed: (context) async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('完了済みタスクの削除'),
                      content: const Text(
                        '完了済みのタスクをすべて削除します。\nこの操作は取り消せません。よろしいですか？',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('キャンセル'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(
                              context,
                            ).colorScheme.error,
                          ),
                          child: const Text('削除する'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    try {
                      final count = await TodoRepository()
                          .deleteCompletedTodos();
                      onReload(); // Reload UI
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$count 件のタスクを削除しました')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('削除エラー: $e')));
                      }
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
                leading: const Icon(Icons.brightness_6),
                title: const Text('テーマ設定'),
                value: Text(
                  currentThemeMode == ThemeMode.system
                      ? 'システム'
                      : currentThemeMode == ThemeMode.light
                      ? 'ライト'
                      : 'ダーク',
                ),
                onPressed: (context) {
                  showDialog(
                    context: context,
                    builder: (context) => SimpleDialog(
                      title: const Text('テーマを選択'),
                      children: [
                        SimpleDialogOption(
                          onPressed: () {
                            onThemeChanged(ThemeMode.system);
                            Navigator.pop(context);
                          },
                          child: const Text('システムデフォルト'),
                        ),
                        SimpleDialogOption(
                          onPressed: () {
                            onThemeChanged(ThemeMode.light);
                            Navigator.pop(context);
                          },
                          child: const Text('ライトモード'),
                        ),
                        SimpleDialogOption(
                          onPressed: () {
                            onThemeChanged(ThemeMode.dark);
                            Navigator.pop(context);
                          },
                          child: const Text('ダークモード'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              SettingsTile.navigation(
                leading: const Icon(Icons.keyboard),
                title: const Text('ショートカットキー一覧'),
                onPressed: (context) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('キーボードショートカット'),
                      content: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            ListTile(
                              title: Text('新規タスク作成'),
                              subtitle: Text('Alt + N'),
                            ),
                            ListTile(
                              title: Text('タスク保存 (作成・編集画面)'),
                              subtitle: Text('Ctrl + Enter'),
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('閉じる'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          SettingsSection(
            title: const Text('タスク設定'),
            tiles: <SettingsTile>[
              SettingsTile.navigation(
                leading: const Icon(Icons.label),
                title: const Text('アジェンダ・コンテキスト設定'),
                onPressed: (context) {
                  _showContextsDialog(context);
                },
              ),
              SettingsTile.navigation(
                leading: const Icon(Icons.category),
                title: const Text('カテゴリ名カスタマイズ'),
                onPressed: (context) {
                  _showCategoriesDialog(context);
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
              SettingsTile.navigation(
                leading: const Icon(Icons.help_outline),
                title: const Text('デイリースタンドアップとは？'),
                onPressed: (context) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('デイリースタンドアップ'),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              '昨日やったこと (Yesterday)',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text('完了したタスクや進捗があったタスクを共有し、チームに成果を伝えます。'),
                            SizedBox(height: 16),
                            Text(
                              '今日やること (Today)',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text('今日取り組む予定のタスクを宣言し、コミットメントを明確にします。'),
                            SizedBox(height: 16),
                            Text(
                              'ブロッカー (Blockers)',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text('作業の進行を妨げている問題や、誰かの助けが必要な事項を共有します。'),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('閉じる'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showContextsDialog(BuildContext context) {
    showDialog(context: context, builder: (context) => const ContextsEditor());
  }

  void _showCategoriesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CategoriesEditor(),
    );
  }
}


