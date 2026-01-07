import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/todo.dart';
import 'todo_add_view.dart';

class ProjectDashboard extends StatelessWidget {
  const ProjectDashboard({
    super.key,
    required this.todos,
    required this.onEdit,
    required this.onUpdate,
  });

  final List<Todo> todos;
  final Function(Todo) onEdit;
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    final projects = todos
        .where((t) => !t.isDone && t.categoryId == 'project')
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('プロジェクト・ポートフォリオ'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: projects.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.folder_open, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    '進行中のプロジェクトはありません',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
              ),
              itemCount: projects.length,
              itemBuilder: (context, index) {
                final project = projects[index];
                return _buildProjectCard(context, project);
              },
            ),
    );
  }

  Widget _buildProjectCard(BuildContext context, Todo project) {
    final subTasks = project.subTasks;
    final total = subTasks.length;
    final done = subTasks.where((s) => s.isDone).length;
    final progress = total > 0 ? done / total : 0.0;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      child: InkWell(
        onTap: () async {
          // Re-use standard edit view for now, which supports subtask editing
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => TodoAddView(todo: project)),
          );
          if (result != null) {
            // If we get a result (updated todo), we might need to handle it.
            // But generally data updates are handled via repository/main screen reload.
            // The current pattern in MainScreen is simple reload on route return usually,
            // or passing specific update callbacks.
            // We passed `onEdit` but TodoAddView returns the object.
            // We should probably call `onEdit(result)` or similar if we want to save.
            // Wait, MainScreen._editTodo handles the push and save.
            // Here we are pushing TodoAddView DIRECTLY.
            // We should probably use the provided `onEdit` callback if possible,
            // BUT `onEdit` in MainScreen expects to do the navigation itself.
            // Let's check MainScreen._editTodo signature.
            // It takes a Todo.
            onEdit(project);
            // Wait, onEdit(project) in MainScreen does:
            // Navigator.push(TodoAddView) -> await -> repo.update -> setState
            // So checking calling onEdit(project) is correct interaction.
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (project.priority != Priority.none)
                    project.priority.badge!,
                  if (project.dueDate != null)
                    Text(
                      DateFormat.MMMd().format(project.dueDate!),
                      style: TextStyle(
                        fontSize: 12,
                        color: project.dueDate!.isBefore(DateTime.now())
                            ? Colors.red
                            : Colors.grey,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                project.title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Text(
                '$done / $total',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[200],
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
              const SizedBox(height: 8),
              // Next Action Preview (First incomplete subtask)
              if (subTasks.any((s) => !s.isDone))
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.secondaryContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.arrow_forward,
                        size: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSecondaryContainer,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          subTasks.firstWhere((s) => !s.isDone).title,
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSecondaryContainer,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
