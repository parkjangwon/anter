import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xterm/xterm.dart';
import 'package:anter/src/core/database/database.dart';
import '../data/ssh_service.dart';
import '../data/local_terminal_service.dart';
import '../../settings/presentation/settings_provider.dart';
import 'web_view_sheet.dart';

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
      appBar: AppBar(
        title: Text(widget.session.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.web, color: Colors.blueAccent),
            tooltip: 'Smart Tunnel & Web View',
            onPressed: _handleSmartTunnel,
          ),
        ],
      ),
      body: SafeArea(
        child: TerminalView(
          _terminal,
          controller: _terminalController,
          textStyle: TerminalStyle(
            fontSize: settings.fontSize,
            fontFamily: settings.fontFamily,
          ),
          autofocus: true,
          focusNode: FocusNode()..requestFocus(),
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

  void _handleSmartTunnel() {
    if (widget.session.host == 'local') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Smart Tunnel unavailable in local shell'),
        ),
      );
      return;
    }
    _showSmartTunnelMenu();
  }

  void _showSmartTunnelMenu() {
    final ports =
        widget.session.smartTunnelPorts
            ?.split(',')
            .where((e) => e.isNotEmpty)
            .map((e) => int.tryParse(e))
            .whereType<int>()
            .toList() ??
        [];

    if (ports.isEmpty) {
      _showCustomPortDialog();
    } else {
      showModalBottomSheet(
        context: context,
        builder: (context) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Smart Tunneling',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            ...ports.map(
              (port) => ListTile(
                title: Text('Forward Port $port'),
                subtitle: Text('localhost:$port'),
                leading: const Icon(Icons.lan),
                onTap: () {
                  Navigator.pop(context);
                  _startTunnelAndOpenWeb(port);
                },
              ),
            ),
            const Divider(),
            ListTile(
              title: const Text('Custom Port'),
              leading: const Icon(Icons.add),
              onTap: () {
                Navigator.pop(context);
                _showCustomPortDialog();
              },
            ),
          ],
        ),
      );
    }
  }

  void _showCustomPortDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Remote Port'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. 8080',
            labelText: 'Port',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final port = int.tryParse(controller.text);
              if (port != null) _startTunnelAndOpenWeb(port);
            },
            child: const Text('Connect'),
          ),
        ],
      ),
    );
  }

  Future<void> _startTunnelAndOpenWeb(int remotePort) async {
    int? localPort;
    try {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Starting tunnel to port $remotePort...'),
          duration: const Duration(seconds: 1),
        ),
      );

      localPort = await _sshService.startForwarding(remotePort: remotePort);

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) => ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: WebViewSheet(
              url: 'http://localhost:$localPort',
              onClose: () => Navigator.pop(context),
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to tunnel: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (localPort != null) {
        await _sshService.stopForwarding(localPort);
      }
    }
  }
}
