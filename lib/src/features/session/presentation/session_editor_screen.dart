import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
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
      _safetyLevel = widget.session!.safetyLevel;
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
    super.dispose();
  }

  void _saveSession() async {
    if (_formKey.currentState!.validate()) {
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
          _passwordController.text.isEmpty ? null : _passwordController.text,
        ),
        safetyLevel: drift.Value(_safetyLevel),
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
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
