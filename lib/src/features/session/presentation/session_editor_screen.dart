import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:file_picker/file_picker.dart';
import '../../../core/database/database.dart';
import '../data/session_repository.dart';

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
  final _smartTunnelPortsController = TextEditingController();

  String? _privateKeyPath;
  bool _usePemKey = false;
  int _safetyLevel = 0;

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
      _safetyLevel = widget.session!.safetyLevel;
      _smartTunnelPortsController.text = widget.session!.smartTunnelPorts ?? '';

      if (_privateKeyPath != null && _privateKeyPath!.isNotEmpty) {
        _usePemKey = true;
      }
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
    _smartTunnelPortsController.dispose();
    super.dispose();
  }

  Future<void> _pickPrivateKey() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() {
        _privateKeyPath = result.files.single.path;
      });
    }
  }

  void _saveSession() async {
    if (_formKey.currentState!.validate()) {
      // Validate that at least one auth method is provided
      if (_usePemKey) {
        if (_privateKeyPath == null || _privateKeyPath!.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a private key file')),
          );
          return;
        }
      }
      // Password validation is optional (could be empty password)

      final session = SessionsCompanion(
        id: widget.session == null
            ? const drift.Value.absent()
            : drift.Value(widget.session!.id),
        name: drift.Value(_nameController.text),
        tag: drift.Value(
          _tagController.text.isEmpty ? null : _tagController.text,
        ),
        host: drift.Value(_hostController.text),
        port: drift.Value(int.parse(_portController.text)),
        username: drift.Value(_usernameController.text),
        password: drift.Value(
          !_usePemKey && _passwordController.text.isNotEmpty
              ? _passwordController.text
              : null,
        ),
        privateKeyPath: drift.Value(_usePemKey ? _privateKeyPath : null),
        passphrase: drift.Value(
          _usePemKey && _passphraseController.text.isNotEmpty
              ? _passphraseController.text
              : null,
        ),
        safetyLevel: drift.Value(_safetyLevel),
        smartTunnelPorts: drift.Value(
          _smartTunnelPortsController.text.isEmpty
              ? null
              : _smartTunnelPortsController.text,
        ),
      );
      await ref.read(sessionRepositoryProvider.notifier).upsert(session);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMacOS = Theme.of(context).platform == TargetPlatform.macOS;
    final double topPadding = isMacOS ? 28.0 : 0.0;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: kToolbarHeight + topPadding,
        leading: isMacOS
            ? Padding(
                padding: EdgeInsets.only(top: topPadding),
                child: const BackButton(),
              )
            : null,
        title: Padding(
          padding: EdgeInsets.only(top: topPadding),
          child: Text(widget.session == null ? 'New Session' : 'Edit Session'),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(top: topPadding, right: 8.0),
            child: IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveSession,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter a name' : null,
              ),
              TextFormField(
                controller: _tagController,
                decoration: const InputDecoration(labelText: 'Tag'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _safetyLevel,
                decoration: const InputDecoration(
                  labelText: 'Production Guard (Safety Level)',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 0,
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline, color: Colors.green),
                        SizedBox(width: 8),
                        Text('None (Safe)'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 1,
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Caution (Yellow)'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 2,
                    child: Row(
                      children: [
                        Icon(Icons.dangerous, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Production (Red)'),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _safetyLevel = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _hostController,
                decoration: const InputDecoration(labelText: 'Host'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter a host' : null,
              ),
              TextFormField(
                controller: _portController,
                decoration: const InputDecoration(labelText: 'Port'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a port';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter a username' : null,
              ),
              TextFormField(
                controller: _smartTunnelPortsController,
                decoration: const InputDecoration(
                  labelText: 'Smart Tunnel Ports (comma separated)',
                  hintText: 'e.g. 8080, 3000, 5000',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Authentication',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Password'),
                      value: false,
                      groupValue: _usePemKey,
                      onChanged: (value) {
                        setState(() {
                          _usePemKey = value!;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<bool>(
                      title: const Text('Private Key'),
                      value: true,
                      groupValue: _usePemKey,
                      onChanged: (value) {
                        setState(() {
                          _usePemKey = value!;
                        });
                      },
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              if (!_usePemKey)
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                )
              else ...[
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickPrivateKey,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Private Key Path',
                      border: OutlineInputBorder(),
                      suffixIcon: Icon(Icons.folder_open),
                    ),
                    child: Text(
                      _privateKeyPath ?? 'Select a file...',
                      style: TextStyle(
                        color: _privateKeyPath == null ? Colors.grey : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (_privateKeyPath == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 12),
                    child: Text(
                      'Required',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passphraseController,
                  decoration: const InputDecoration(
                    labelText: 'Passphrase (Optional)',
                    helperText: 'Leave empty if the key is not encrypted',
                  ),
                  obscureText: true,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
