import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/shortcut_action.dart';
import '../shortcuts_provider.dart';

class ShortcutSettingsSection extends ConsumerWidget {
  const ShortcutSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shortcuts = ref.watch(shortcutsProvider);
    final notifier = ref.read(shortcutsProvider.notifier);

    // Group by category, excluding internal shortcuts
    final groupedShortcuts = <ShortcutCategory, List<ShortcutAction>>{};
    for (final action in ShortcutAction.values) {
      if (action == ShortcutAction.nextTab ||
          action == ShortcutAction.previousTab) {
        continue;
      }
      groupedShortcuts.putIfAbsent(action.category, () => []).add(action);
    }

    return ExpansionTile(
      leading: const Icon(Icons.keyboard),
      title: const Text(
        'Keyboard Shortcuts',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      initiallyExpanded: false, // Folding by default
      children: [
        for (final category in ShortcutCategory.values) ...[
          if (groupedShortcuts.containsKey(category))
            _buildCategorySection(
              context,
              category,
              groupedShortcuts[category]!,
              shortcuts,
              notifier,
            ),
        ],
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Reset Shortcuts'),
                  content: const Text(
                    'Are you sure you want to reset all shortcuts to default?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        notifier.resetToDefaults();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              );
            },
            child: const Text('Reset to Defaults'),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    ShortcutCategory category,
    List<ShortcutAction> actions,
    Map<ShortcutAction, List<ShortcutActivator>> shortcuts,
    ShortcutsNotifier notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            category.label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        ...actions.map((action) {
          final activators = shortcuts[action] ?? [];
          return ListTile(
            title: Text(action.label, style: const TextStyle(fontSize: 14)),
            trailing: Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ...activators.map(
                  (activator) => InputChip(
                    label: Text(
                      AppShortcutSerialization.toStringDisplay(activator),
                    ),
                    onDeleted: () => notifier.removeShortcut(action, activator),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add, size: 20),
                  onPressed: () async {
                    final newActivator = await showDialog<ShortcutActivator>(
                      context: context,
                      builder: (context) => const KeyRecorderDialog(),
                    );
                    if (newActivator != null) {
                      notifier.addShortcut(action, newActivator);
                    }
                  },
                  tooltip: 'Add Shortcut',
                ),
              ],
            ),
          );
        }),
        const Divider(),
      ],
    );
  }
}

class KeyRecorderDialog extends StatefulWidget {
  const KeyRecorderDialog({super.key});

  @override
  State<KeyRecorderDialog> createState() => _KeyRecorderDialogState();
}

class _KeyRecorderDialogState extends State<KeyRecorderDialog> {
  final FocusNode _focusNode = FocusNode();
  final Set<LogicalKeyboardKey> _currentKeys = {}; // Physically pressed keys
  ShortcutActivator? _recordedActivator; // The combination to save

  @override
  void initState() {
    super.initState();
    // Auto focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          setState(() {
            _currentKeys.add(event.logicalKey);
            _updateRecordedActivator();
          });
          return KeyEventResult.handled;
        } else if (event is KeyUpEvent) {
          setState(() {
            _currentKeys.remove(event.logicalKey);
            // We do NOT clear _recordedActivator here, so the display holds the last combo
          });
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: AlertDialog(
        title: const Text('Record Shortcut'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Press the key combination you want to use.'),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: Text(
                _getDisplayString(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: _recordedActivator == null
                ? null
                : () {
                    Navigator.of(context).pop(_recordedActivator);
                  },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _updateRecordedActivator() {
    // Try to create an activator from the currently pressed keys
    final activator = _createActivatorFromKeys(_currentKeys);
    if (activator != null) {
      _recordedActivator = activator;
    }
  }

  String _getDisplayString() {
    if (_recordedActivator != null) {
      return AppShortcutSerialization.toStringDisplay(_recordedActivator!);
    }
    if (_currentKeys.isNotEmpty) {
      // Fallback to showing raw keys if we haven't formed a valid activator yet (e.g. just modifiers)
      return _currentKeys.map((k) => k.keyLabel).join(' + ');
    }
    return 'Waiting for input...';
  }

  ShortcutActivator? _createActivatorFromKeys(Set<LogicalKeyboardKey> keys) {
    LogicalKeyboardKey? trigger;
    for (final key in keys) {
      if (!_isModifier(key)) {
        trigger = key;
        break;
      }
    }

    if (trigger == null) return null;

    return SingleActivator(
      trigger,
      control:
          keys.contains(LogicalKeyboardKey.controlLeft) ||
          keys.contains(LogicalKeyboardKey.controlRight),
      shift:
          keys.contains(LogicalKeyboardKey.shiftLeft) ||
          keys.contains(LogicalKeyboardKey.shiftRight),
      alt:
          keys.contains(LogicalKeyboardKey.altLeft) ||
          keys.contains(LogicalKeyboardKey.altRight),
      meta:
          keys.contains(LogicalKeyboardKey.metaLeft) ||
          keys.contains(LogicalKeyboardKey.metaRight),
    );
  }

  bool _isModifier(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.metaLeft ||
        key == LogicalKeyboardKey.metaRight ||
        key == LogicalKeyboardKey.controlLeft ||
        key == LogicalKeyboardKey.controlRight ||
        key == LogicalKeyboardKey.altLeft ||
        key == LogicalKeyboardKey.altRight ||
        key == LogicalKeyboardKey.shiftLeft ||
        key == LogicalKeyboardKey.shiftRight;
  }
}
