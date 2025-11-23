import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xterm/xterm.dart';
import 'package:anter/src/core/database/database.dart';
import '../data/ssh_service.dart';
import '../data/local_terminal_service.dart';
import '../../settings/presentation/settings_provider.dart';

class TerminalScreen extends ConsumerStatefulWidget {
  final Session session;

  const TerminalScreen({super.key, required this.session});

  @override
  ConsumerState<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends ConsumerState<TerminalScreen> {
  late final Terminal _terminal;
  final _terminalController = TerminalController();
  final _sshService = SSHService();
  final _localService = LocalTerminalService();

  @override
  void initState() {
    super.initState();
    _terminal = Terminal(maxLines: 10000);

    if (widget.session.host == 'local') {
      _startLocal();
    } else {
      _connectSSH();
    }
  }

  Future<void> _startLocal() async {
    await _localService.start(_terminal);
  }

  Future<void> _connectSSH() async {
    await _sshService.connect(
      host: widget.session.host,
      port: widget.session.port,
      username: widget.session.username,
      password: widget.session.password,
      privateKeyPath: widget.session.privateKeyPath,
      passphrase: widget.session.passphrase,
      terminal: _terminal,
    );
  }

  @override
  void dispose() {
    _sshService.dispose();
    _localService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(widget.session.name)),
      body: SafeArea(
        child: TerminalView(
          _terminal,
          controller: _terminalController,
          textStyle: TerminalStyle(
            fontSize: settings.fontSize,
            fontFamily: settings.fontFamily,
          ),
          autofocus: true,
          focusNode: FocusNode()..requestFocus(), // Force focus
          backgroundOpacity: 0.9,
          onSecondaryTapDown: (details, offset) async {
            final selection = _terminalController.selection;
            if (selection != null) {
              _terminalController.clearSelection();
              // TODO: Copy to clipboard
            } else {
              // TODO: Paste from clipboard
            }
          },
        ),
      ),
    );
  }
}
