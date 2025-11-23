import 'package:flutter/material.dart';

/// Widget for editing a single script step
class ScriptStepEditor extends StatefulWidget {
  final String keyword;
  final String command;
  final int delayMs;
  final ValueChanged<String> onKeywordChanged;
  final ValueChanged<String> onCommandChanged;
  final ValueChanged<int> onDelayChanged;
  final VoidCallback onDelete;
  final bool canDelete;

  const ScriptStepEditor({
    super.key,
    required this.keyword,
    required this.command,
    required this.delayMs,
    required this.onKeywordChanged,
    required this.onCommandChanged,
    required this.onDelayChanged,
    required this.onDelete,
    this.canDelete = true,
  });

  @override
  State<ScriptStepEditor> createState() => _ScriptStepEditorState();
}

class _ScriptStepEditorState extends State<ScriptStepEditor> {
  late TextEditingController _keywordController;
  late TextEditingController _commandController;
  late TextEditingController _delayController;

  @override
  void initState() {
    super.initState();
    _keywordController = TextEditingController(text: widget.keyword);
    _commandController = TextEditingController(text: widget.command);
    _delayController = TextEditingController(
      text: widget.delayMs > 0 ? widget.delayMs.toString() : '',
    );
  }

  @override
  void dispose() {
    _keywordController.dispose();
    _commandController.dispose();
    _delayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Keyword field
            Expanded(
              flex: 1,
              child: TextField(
                controller: _keywordController,
                decoration: const InputDecoration(
                  labelText: 'Wait for keyword',
                  hintText: r'$',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: widget.onKeywordChanged,
              ),
            ),
            const SizedBox(width: 8),

            // Command field
            Expanded(
              flex: 3,
              child: TextField(
                controller: _commandController,
                decoration: const InputDecoration(
                  labelText: 'Execute command',
                  hintText: 'ls -la',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: widget.onCommandChanged,
              ),
            ),
            const SizedBox(width: 8),

            // Delay field
            SizedBox(
              width: 100,
              child: TextField(
                controller: _delayController,
                decoration: const InputDecoration(
                  labelText: 'Delay (ms)',
                  hintText: '0',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final delay = int.tryParse(value) ?? 0;
                  widget.onDelayChanged(delay);
                },
              ),
            ),
            const SizedBox(width: 8),

            // Delete button
            if (widget.canDelete)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: Colors.red[300],
                onPressed: widget.onDelete,
                tooltip: 'Remove step',
              ),
          ],
        ),
      ),
    );
  }
}
