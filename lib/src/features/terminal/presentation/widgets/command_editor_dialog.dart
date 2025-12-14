import 'package:flutter/material.dart';

class CommandEditorDialog extends StatefulWidget {
  final String? initialLabel;
  final String? initialCommand;

  const CommandEditorDialog({
    super.key,
    this.initialLabel,
    this.initialCommand,
  });

  @override
  State<CommandEditorDialog> createState() => _CommandEditorDialogState();
}

class _CommandEditorDialogState extends State<CommandEditorDialog> {
  late TextEditingController _labelController;
  late TextEditingController _commandController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.initialLabel);
    _commandController = TextEditingController(text: widget.initialCommand);
  }

  @override
  void dispose() {
    _labelController.dispose();
    _commandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialLabel == null ? 'Add Command' : 'Edit Command'),
      content: getForm(context),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop({
                'label': _labelController.text.trim(),
                'command': _commandController.text,
              });
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget getForm(BuildContext context) {
    return SizedBox(
      width: 400,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: 'Label',
                hintText: 'e.g. Restart Docker',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Label is required';
                }
                if (value.length > 20) {
                  return 'Label too long (max 20 chars)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _commandController,
              decoration: const InputDecoration(
                labelText: 'Command',
                hintText: 'e.g. docker-compose restart',
                border: OutlineInputBorder(),
                helperText: 'Using "\\r" is optional, appended automatically.',
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Command is required';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}
