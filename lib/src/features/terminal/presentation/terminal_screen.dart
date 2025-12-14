import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:xterm/xterm.dart';
import 'package:anter/src/core/database/database.dart';
import '../data/ssh_service.dart';
import '../data/local_terminal_service.dart';
import '../../settings/presentation/settings_provider.dart';
import '../../settings/domain/shortcut_intents.dart';
import '../application/terminal_input_handler.dart';
import '../../ai_assistant/presentation/ai_analysis_overlay.dart';
import 'web_view_sheet.dart';
import 'dart:io';
import 'widgets/virtual_key_toolbar.dart';
import 'widgets/button_bar_widget.dart';

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
  late final FocusNode _focusNode;

  bool _isCtrlPressed = false;
  bool _isAltPressed = false;
  bool _showAiOverlay = false;
  Function(String)? _originalOnOutput;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _terminal = Terminal(maxLines: 10000);

    // Initialize connection and then setup interception
    _initConnection();
  }

  Future<void> _initConnection() async {
    if (widget.session.host == 'local') {
      await _startLocal();
    } else {
      await _connectSSH();
    }
    _setupOutputInterception();
  }

  void _setupOutputInterception() {
    // Preserve existing handler (from SSHService or LocalTerminalService)
    _originalOnOutput = _terminal.onOutput;

    // Wrap with Input Transformation
    _terminal.onOutput = (input) {
      String effectiveInput = input;
      if (_isCtrlPressed || _isAltPressed) {
        effectiveInput = KeyModifierHandler.transformInput(
          input,
          isCtrl: _isCtrlPressed,
          isAlt: _isAltPressed,
        );

        // Reset modifiers (One-shot behavior)
        if (mounted) {
          setState(() {
            _isCtrlPressed = false;
            _isAltPressed = false;
          });
        }
      }

      // Backspace Compatibility (Replace DEL \x7f with BS \x08 if mode == 1)
      if (widget.session.backspaceMode == 1) {
        effectiveInput = effectiveInput.replaceAll('\x7f', '\x08');
      }

      // Delegate to original handler
      _originalOnOutput?.call(effectiveInput);
    };
  }

  Future<void> _startLocal() async {
    await _localService.start(_terminal);
  }

  Future<void> _connectSSH() async {
    // Note: TerminalScreen currently only supports direct connection or manually resolved chains.
    // To support ProxyJump here, we would need to resolve the chain similar to TabManager.
    // For now, we wrap the single session.
    await _sshService.connect(hops: [widget.session], terminal: _terminal);
  }

  void _handleAiAnalysis() {
    setState(() {
      _showAiOverlay = true;
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
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
        child: Actions(
          actions: {
            AiAssistantIntent: CallbackAction<AiAssistantIntent>(
              onInvoke: (_) {
                _handleAiAnalysis();
                return null;
              },
            ),
          },
          child: Shortcuts(
            shortcuts: {
              // Desktop Shortcut for AI: Ctrl+Shift+I (or Cmd+Shift+I)
              const SingleActivator(
                LogicalKeyboardKey.keyI,
                control: true,
                shift: true,
              ): const AiAssistantIntent(),
              const SingleActivator(
                LogicalKeyboardKey.keyI,
                meta: true,
                shift: true,
              ): const AiAssistantIntent(),
            },
            child: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: TerminalView(
                        _terminal,
                        controller: _terminalController,
                        textStyle: TerminalStyle(
                          fontSize: settings.fontSize,
                          fontFamily: settings.fontFamily,
                        ),
                        autofocus: true,
                        focusNode: _focusNode,
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
                    ButtonBarWidget(
                      onCommand: (cmd) => _terminal.onOutput?.call(cmd),
                    ),
                    if (Platform.isAndroid || Platform.isIOS)
                      VirtualKeyToolbar(
                        terminal: _terminal,
                        isCtrlPressed: _isCtrlPressed,
                        isAltPressed: _isAltPressed,
                        onCtrlToggle: (start) =>
                            setState(() => _isCtrlPressed = start),
                        onAltToggle: (start) =>
                            setState(() => _isAltPressed = start),
                        onAiHelp: _handleAiAnalysis,
                      ),
                  ],
                ),
                if (_showAiOverlay)
                  AIAnalysisOverlay(
                    terminal: _terminal,
                    onClose: () => setState(() => _showAiOverlay = false),
                  ),
              ],
            ),
          ),
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
