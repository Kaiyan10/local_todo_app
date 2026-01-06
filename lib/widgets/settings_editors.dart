import 'package:flutter/material.dart';
import '../data/settings_service.dart';
import '../data/category_model.dart' as model;
import '../data/todo_repository.dart';

class ContextsEditor extends StatefulWidget {
  const ContextsEditor({super.key});

  @override
  State<ContextsEditor> createState() => _ContextsEditorState();
}

class _ContextsEditorState extends State<ContextsEditor> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsService(),
      builder: (context, child) {
        final contexts = SettingsService().contexts;
        return AlertDialog(
          title: const Text('コンテキスト設定'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: '新しいタグ (例: @Gym)',
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        if (_controller.text.isNotEmpty) {
                          String tag = _controller.text.trim();
                          if (!tag.startsWith('@')) {
                            tag = '@$tag';
                          }
                          SettingsService().addContext(tag);
                          _controller.clear();
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: contexts.length,
                    itemBuilder: (context, index) {
                      final tag = contexts[index];
                      return ListTile(
                        title: Text(tag),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            SettingsService().removeContext(tag);
                          },
                        ),
                      );
                    },
                  ),
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
        );
      },
    );
  }
}

class CategoriesEditor extends StatefulWidget {
  const CategoriesEditor({super.key});

  @override
  State<CategoriesEditor> createState() => _CategoriesEditorState();
}

class _CategoriesEditorState extends State<CategoriesEditor> {
  final _textController = TextEditingController();

  void _showRenameDialog(BuildContext context, model.Category category) {
    _textController.text = category.name;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('カテゴリ名を変更'),
          content: TextField(
            controller: _textController,
            decoration: const InputDecoration(labelText: '新しい名前'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                final newName = _textController.text.trim();
                if (newName.isNotEmpty) {
                  SettingsService().updateCategory(category.id, newName);
                }
                Navigator.pop(context);
              },
              child: const Text('保存'),
            ),
          ],
        );
      },
    );
  }

  void _showAddDialog(BuildContext context) {
    _textController.clear();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('新しいカテゴリを追加'),
          content: TextField(
            controller: _textController,
            decoration: const InputDecoration(labelText: 'カテゴリ名'),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                final newName = _textController.text.trim();
                if (newName.isNotEmpty) {
                  SettingsService().addCategory(newName);
                }
                Navigator.pop(context);
              },
              child: const Text('追加'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, model.Category category) async {
    final hasActiveTasks = await TodoRepository().hasActiveTodosForCategory(category.id);

    if (!context.mounted) return;

    if (hasActiveTasks) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('削除できません'),
            content: Text(
              '「${category.name}」には未完了のタスクが含まれています。\n'
              '先にタスクを完了するか、別のカテゴリに移動してください。'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('カテゴリを削除'),
          content: Text('「${category.name}」を削除してもよろしいですか？\n'
              'この操作は取り消せません。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル'),
            ),
            TextButton(
              onPressed: () {
                SettingsService().deleteCategory(category.id);
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('削除'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsService(),
      builder: (context, _) {
        final categories = SettingsService().categories;
        return AlertDialog(
          title: const Text('カテゴリ設定'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'カスタマイズ可能なカテゴリ',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('追加'),
                      onPressed: () => _showAddDialog(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (categories.isEmpty)
                  const Text('カテゴリがありません', style: TextStyle(color: Colors.grey))
                else
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 8.0,
                    children: categories.map((model.Category category) {
                      return InputChip(
                        label: Text(category.name),
                        backgroundColor: category.isSystem
                            ? Theme.of(context).colorScheme.surfaceContainerHighest
                            : null,
                        onPressed: () => _showRenameDialog(context, category),
                        onDeleted: category.isSystem
                            ? null
                            : () => _confirmDelete(context, category),
                        deleteIcon: const Icon(Icons.close, size: 16),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 8),
                const Text(
                  '※システムカテゴリ（グレー）は削除できません。タップして名前を変更できます。',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
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
        );
      },
    );
  }
}
