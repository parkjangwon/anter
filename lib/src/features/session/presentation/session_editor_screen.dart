import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:anter/l10n/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/database/database.dart';
import '../data/session_repository.dart';
import '../../terminal/domain/script_step.dart';
import 'widgets/script_step_editor.dart';

class SessionEditorScreen extends ConsumerStatefulWidget {
  final Session? session;

  const SessionEditorScreen({super.key, this.session});

  @override
  ConsumerState<SessionEditorScreen> createState() =>
      _SessionEditorScreenState();
}

class _SessionEditorScreenState extends ConsumerState<SessionEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _tagController = TextEditingController();
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '22');
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passphraseController = TextEditingController();
  String? _privateKeyPath;
  LoginScript _loginScript = const LoginScript();
  bool _executeLoginScript = false;
  bool _showLoginScript = false;
  bool _usePrivateKey = false;

  @override
  void initState() {
    super.initState();
    if (widget.session != null) {
      _nameController.text = widget.session!.name;
      _tagController.text = widget.session!.tag ?? '';
      _hostController.text = widget.session!.host;
      _portController.text = widget.session!.port.toString();
      _usernameController.text = widget.session!.username;
      _passwordController.text = widget.session!.password ?? '';
      _privateKeyPath = widget.session!.privateKeyPath;
      _passphraseController.text = widget.session!.passphrase ?? '';
      _usePrivateKey = _privateKeyPath != null && _privateKeyPath!.isNotEmpty;
      if (widget.session!.loginScript != null &&
          widget.session!.loginScript!.isNotEmpty) {
        _loginScript = LoginScript.fromJson(widget.session!.loginScript!);
      }
      _executeLoginScript = widget.session!.executeLoginScript;
      _showLoginScript = _loginScript.isNotEmpty;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tagController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _passphraseController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final session = SessionsCompanion(
        id: widget.session != null
            ? drift.Value(widget.session!.id)
            : const drift.Value.absent(),
        name: drift.Value(_nameController.text),
        tag: drift.Value(
          _tagController.text.isEmpty ? null : _tagController.text,
        ),
        host: drift.Value(_hostController.text),
        port: drift.Value(int.parse(_portController.text)),
        username: drift.Value(_usernameController.text),
        password: drift.Value(
          _passwordController.text.isEmpty ? null : _passwordController.text,
        ),
        privateKeyPath: drift.Value(_privateKeyPath),
        passphrase: drift.Value(
          _passphraseController.text.isEmpty
              ? null
              : _passphraseController.text,
        ),
        loginScript: drift.Value(
          _loginScript.isEmpty ? null : _loginScript.toJson(),
        ),
        executeLoginScript: drift.Value(_executeLoginScript),
      );

      if (widget.session != null) {
        await ref
            .read(sessionRepositoryProvider.notifier)
            .updateSession(session);
      } else {
        await ref.read(sessionRepositoryProvider.notifier).addSession(session);
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.session != null ? 'Edit Session' : 'New Session'),
        actions: [IconButton(onPressed: _save, icon: const Icon(Icons.save))],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (Theme.of(context).platform == TargetPlatform.macOS)
              const SizedBox(height: 28),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tagController,
              decoration: const InputDecoration(
                labelText: 'Tag (optional)',
                prefixText: '#',
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _hostController,
                    decoration: InputDecoration(labelText: l10n.host),
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _portController,
                    decoration: InputDecoration(labelText: l10n.port),
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: l10n.username),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: l10n.password,
                enabled: !_usePrivateKey,
              ),
              obscureText: true,
              enabled: !_usePrivateKey,
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),
            // Authentication Method
            Row(
              children: [
                const Icon(Icons.vpn_key, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Authentication Method',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Use Private Key (PEM)'),
              subtitle: const Text('Authenticate using SSH private key file'),
              value: _usePrivateKey,
              onChanged: (value) {
                setState(() {
                  _usePrivateKey = value;
                  if (!value) {
                    _privateKeyPath = null;
                    _passphraseController.clear();
                  }
                });
              },
            ),
            if (_usePrivateKey) const SizedBox(height: 16),
            if (_usePrivateKey)
              ListTile(
                title: Text(
                  _privateKeyPath ?? 'No key file selected',
                  style: TextStyle(
                    color: _privateKeyPath != null ? null : Colors.grey,
                  ),
                ),
                subtitle: const Text('Private key file path'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_privateKeyPath != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _privateKeyPath = null;
                          });
                        },
                      ),
                    ElevatedButton.icon(
                      onPressed: _pickPrivateKeyFile,
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Browse'),
                    ),
                  ],
                ),
              ),
            if (_usePrivateKey) const SizedBox(height: 16),
            if (_usePrivateKey)
              TextFormField(
                controller: _passphraseController,
                decoration: const InputDecoration(
                  labelText: 'Passphrase (optional)',
                  hintText: 'Enter passphrase if key is encrypted',
                ),
                obscureText: true,
              ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 8),
            // Login Script Section
            Row(
              children: [
                const Icon(Icons.code, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Login Script',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _showLoginScript = !_showLoginScript;
                    });
                  },
                  icon: Icon(
                    _showLoginScript ? Icons.expand_less : Icons.expand_more,
                  ),
                  label: Text(_showLoginScript ? 'Hide' : 'Show'),
                ),
              ],
            ),
            if (_showLoginScript) const SizedBox(height: 16),
            if (_showLoginScript)
              SwitchListTile(
                title: const Text('Execute login script automatically'),
                subtitle: const Text('Run commands when keywords are matched'),
                value: _executeLoginScript,
                onChanged: (value) {
                  setState(() {
                    _executeLoginScript = value;
                  });
                },
              ),
            if (_showLoginScript) const SizedBox(height: 16),
            if (_showLoginScript) ..._buildScriptSteps(),
            if (_showLoginScript) const SizedBox(height: 8),
            if (_showLoginScript)
              ElevatedButton.icon(
                onPressed: _addScriptStep,
                icon: const Icon(Icons.add),
                label: const Text('Add Step'),
              ),
            if (_showLoginScript) const SizedBox(height: 8),
            if (_showLoginScript)
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Each step waits for a keyword in terminal output, then executes a command',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildScriptSteps() {
    if (_loginScript.steps.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text(
              'No steps added yet. Click "Add Step" to create your first step.',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      ];
    }

    return [
      ReorderableListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) {
              newIndex -= 1;
            }
            final steps = List<ScriptStep>.from(_loginScript.steps);
            final step = steps.removeAt(oldIndex);
            steps.insert(newIndex, step);
            _loginScript = LoginScript(steps: steps);
          });
        },
        children: _loginScript.steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          return Row(
            key: ValueKey(step.id),
            children: [
              // Drag handle
              ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 8),
                  child: Icon(Icons.drag_indicator, color: Colors.grey[400]),
                ),
              ),
              // Script step editor
              Expanded(
                child: ScriptStepEditor(
                  key: ValueKey('${step.id}_editor'),
                  keyword: step.keyword,
                  command: step.command,
                  delayMs: step.delayMs,
                  onKeywordChanged: (value) =>
                      _updateStep(index, keyword: value),
                  onCommandChanged: (value) =>
                      _updateStep(index, command: value),
                  onDelayChanged: (value) => _updateStep(index, delayMs: value),
                  onDelete: () => _deleteStep(index),
                  canDelete: _loginScript.steps.length > 1,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    ];
  }

  void _addScriptStep() {
    setState(() {
      final steps = List<ScriptStep>.from(_loginScript.steps);
      steps.add(ScriptStep(keyword: r'$', command: ''));
      _loginScript = LoginScript(steps: steps);
    });
  }

  void _updateStep(
    int index, {
    String? keyword,
    String? command,
    int? delayMs,
  }) {
    setState(() {
      final steps = List<ScriptStep>.from(_loginScript.steps);
      steps[index] = steps[index].copyWith(
        keyword: keyword,
        command: command,
        delayMs: delayMs,
      );
      _loginScript = LoginScript(steps: steps);
    });
  }

  void _deleteStep(int index) {
    setState(() {
      final steps = List<ScriptStep>.from(_loginScript.steps);
      steps.removeAt(index);
      _loginScript = LoginScript(steps: steps);
    });
  }

  Future<void> _pickPrivateKeyFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pem', 'key', 'ppk'],
      dialogTitle: 'Select Private Key File',
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _privateKeyPath = result.files.single.path;
      });
    }
  }
}
