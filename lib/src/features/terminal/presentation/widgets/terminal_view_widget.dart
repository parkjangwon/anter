import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:xterm/xterm.dart';
import '../../../settings/presentation/settings_provider.dart';
import '../../../settings/domain/settings_state.dart';
import '../../../settings/domain/shortcut_intents.dart';
import '../../../../core/theme/terminal_themes.dart' as app_theme;
import 'dart:io';
import 'virtual_key_toolbar.dart';

class TerminalViewWidget extends ConsumerStatefulWidget {
  final Terminal terminal;
  final FocusNode? focusNode;
  final int safetyLevel; // 0: None, 1: Caution, 2: Production

  const TerminalViewWidget({
    super.key,
    required this.terminal,
    this.focusNode,
    this.safetyLevel = 0,
  });

  @override
  ConsumerState<TerminalViewWidget> createState() => _TerminalViewWidgetState();
}

class _TerminalViewWidgetState extends ConsumerState<TerminalViewWidget>
    with AutomaticKeepAliveClientMixin {
  late FocusNode _internalFocusNode;
  Function(String)? _originalOnOutput;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = widget.focusNode ?? FocusNode();

    if (widget.focusNode == null) {
      _internalFocusNode.requestFocus();
    }

    _setupSafetyGuard();
  }

  void _setupSafetyGuard() {
    // Preserve existing handler (from SSHService or LocalTerminalService)
    _originalOnOutput = widget.terminal.onOutput;

    // Wrap with safety logic
    widget.terminal.onOutput = (input) async {
      // Command Interception Logic for Production Servers
      if (widget.safetyLevel == 2 && (input == '\r' || input == '\n')) {
        final currentLine = widget.terminal.buffer.currentLine.getText();
        final dangerousCommands = [
          'rm -rf',
          'reboot',
          'DROP TABLE',
        ]; // simple check

        bool isDangerous = false;
        for (final cmd in dangerousCommands) {
          if (currentLine.contains(cmd)) {
            isDangerous = true;
            break;
          }
        }

        if (isDangerous) {
          final confirm = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.red),
                  SizedBox(width: 8),
                  Text('PRODUCTION SERVER WARNING'),
                ],
              ),
              content: const Text(
                'You are about to execute a potentially destructive command on a PRODUCTION server.\n\nAre you sure you want to proceed?',
                style: TextStyle(color: Colors.red),
              ),
              // Doesn't apply to dialog directly usually but ok
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('EXECUTE'),
                ),
              ],
            ),
          );

          if (confirm != true) {
            return; // Block execution
          }
        }
      }

      // Delegate to original handler
      _originalOnOutput?.call(input);
    };
  }

  @override
  void dispose() {
    // Restore original handler to avoid side effects if terminal is reused (unlikely but safe)
    if (_originalOnOutput != null) {
      widget.terminal.onOutput = _originalOnOutput;
    }
    if (widget.focusNode == null) {
      _internalFocusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin
    final settings = ref.watch(settingsProvider);

    // Visual Safety Logic
    Color? borderColor;
    Color? backgroundColor;
    double borderWidth = 0;

    if (widget.safetyLevel == 1) {
      // Caution (Yellow)
      borderColor = Colors.yellow[700];
      borderWidth = 2.0;
    } else if (widget.safetyLevel == 2) {
      // Production (Red)
      borderColor = Colors.red;
      backgroundColor = Colors.red.withAlpha(20); // 0.08 * 255 ~= 20
      borderWidth = 3.0;
    }

    return Actions(
      actions: {
        ZoomInIntent: CallbackAction<ZoomInIntent>(
          onInvoke: (_) {
            ref
                .read(settingsProvider.notifier)
                .setFontSize(settings.fontSize + 2);
            return null;
          },
        ),
        ZoomOutIntent: CallbackAction<ZoomOutIntent>(
          onInvoke: (_) {
            ref
                .read(settingsProvider.notifier)
                .setFontSize(settings.fontSize - 2);
            return null;
          },
        ),
        ResetZoomIntent: CallbackAction<ResetZoomIntent>(
          onInvoke: (_) {
            ref.read(settingsProvider.notifier).setFontSize(14.0);
            return null;
          },
        ),
        BlockTabIntent: CallbackAction<BlockTabIntent>(onInvoke: (_) => null),
      },
      child: Shortcuts(
        shortcuts: {
          const SingleActivator(LogicalKeyboardKey.tab, control: true):
              const BlockTabIntent(),
          const SingleActivator(
            LogicalKeyboardKey.tab,
            control: true,
            shift: true,
          ): const BlockTabIntent(),
        },
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            border: borderColor != null
                ? Border.all(color: borderColor, width: borderWidth)
                : null,
          ),
          child: Column(
            children: [
              Expanded(
                child: TerminalView(
                  widget.terminal,
                  textStyle: TerminalStyle(
                    fontSize: settings.fontSize,
                    fontFamily: settings.fontFamily,
                  ),
                  autofocus: true,
                  focusNode: _internalFocusNode,
                  backgroundOpacity: 0, // Ensure background shows through
                  theme: _getTerminalTheme(settings.colorScheme),
                ),
              ),
              if (Platform.isAndroid || Platform.isIOS)
                VirtualKeyToolbar(terminal: widget.terminal),
            ],
          ),
        ),
      ),
    );
  }

  TerminalTheme _getTerminalTheme(TerminalColorScheme scheme) {
    switch (scheme) {
      case TerminalColorScheme.dracula:
        return app_theme.TerminalThemes.dracula;
      case TerminalColorScheme.monokai:
        return app_theme.TerminalThemes.monokai;
      case TerminalColorScheme.solarizedDark:
        return app_theme.TerminalThemes.solarizedDark;
      case TerminalColorScheme.solarizedLight:
        return app_theme.TerminalThemes.solarizedLight;
      case TerminalColorScheme.gruvboxDark:
        return app_theme.TerminalThemes.gruvboxDark;
      case TerminalColorScheme.gruvboxLight:
        return app_theme.TerminalThemes.gruvboxLight;
      case TerminalColorScheme.nord:
        return app_theme.TerminalThemes.nord;
      case TerminalColorScheme.oneDark:
        return app_theme.TerminalThemes.oneDark;
      case TerminalColorScheme.oneLight:
        return app_theme.TerminalThemes.oneLight;
    }
  }
}

class BlockTabIntent extends Intent {
  const BlockTabIntent();
}
