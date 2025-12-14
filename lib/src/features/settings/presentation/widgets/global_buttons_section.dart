import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/global_command_repository.dart';
import '../../../terminal/presentation/widgets/command_editor_dialog.dart';

class GlobalButtonsSection extends ConsumerWidget {
  const GlobalButtonsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commandsAsync = ref.watch(globalCommandsProvider);

    return ExpansionTile(
      leading: const Icon(Icons.smart_button),
      title: const Text('Custom Buttons (Global)'),
      subtitle: const Text('Manage command macros for all sessions'),
      children: [
        commandsAsync.when(
          data: (commands) {
            if (commands.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'No custom buttons yet.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () => _addCommand(context, ref),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Button'),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: true,
                  itemCount: commands.length,
                  onReorder: (oldIndex, newIndex) {
                    if (oldIndex < newIndex) {
                      newIndex -= 1;
                    }
                    final item = commands.removeAt(oldIndex);
                    commands.insert(newIndex, item);

                    final newOrder = commands.map((c) => c.id).toList();
                    ref
                        .read(globalCommandRepositoryProvider)
                        .reorderCommands(newOrder);
                  },
                  itemBuilder: (context, index) {
                    final cmd = commands[index];
                    return ListTile(
                      key: ValueKey(cmd.id),
                      leading: const Icon(Icons.drag_handle),
                      title: Text(cmd.label),
                      subtitle: Text(
                        cmd.command,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _editCommand(context, ref, cmd),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                _deleteCommand(context, ref, cmd.id),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton.icon(
                    onPressed: () => _addCommand(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Button'),
                  ),
                ),
              ],
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, stack) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Error: $err',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _addCommand(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => const CommandEditorDialog(),
    );

    if (result != null) {
      await ref
          .read(globalCommandRepositoryProvider)
          .addCommand(result['label']!, result['command']!);
    }
  }

  Future<void> _editCommand(
    BuildContext context,
    WidgetRef ref,
    dynamic cmd,
  ) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => CommandEditorDialog(
        initialLabel: cmd.label,
        initialCommand: cmd.command,
      ),
    );

    if (result != null) {
      await ref
          .read(globalCommandRepositoryProvider)
          .updateCommand(cmd.id, result['label']!, result['command']!);
    }
  }

  Future<void> _deleteCommand(
    BuildContext context,
    WidgetRef ref,
    int id,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Button'),
        content: const Text('Are you sure you want to delete this button?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(globalCommandRepositoryProvider).deleteCommand(id);
    }
  }
}
