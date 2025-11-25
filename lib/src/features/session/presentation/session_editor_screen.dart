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
            _tagController.text.isEmpty ? null : _tagController.text),
        host: drift.Value(_hostController.text),
        port: drift.Value(int.parse(_portController.text)),
        username: drift.Value(_usernameController.text),
        password: drift.Value(
            _passwordController.text.isEmpty ? null : _passwordController.text),
      );
      await ref.read(sessionRepositoryProvider.notifier).upsert(session);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.session == null ? 'New Session' : 'Edit Session'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveSession,
          ),
        ],
      ),
      body: Form(
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
    );
  }
}
