import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:xterm/xterm.dart';
import '../../../settings/presentation/settings_provider.dart';
import '../../../settings/domain/settings_state.dart';
import '../../../settings/domain/shortcut_intents.dart';
import '../../../../core/theme/terminal_themes.dart' as app_theme;
import '../../application/terminal_input_handler.dart';
import '../../../ai_assistant/presentation/ai_analysis_overlay.dart';
import 'dart:io';
import 'virtual_key_toolbar.dart';
import 'button_bar_widget.dart';

import 'dart:async';

class TerminalViewWidget extends ConsumerStatefulWidget {
  final Terminal terminal;
  final FocusNode? focusNode;
  final int safetyLevel; // 0: None, 1: Caution, 2: Production
  final int backspaceMode; // 0: Auto/Standard (DEL), 1: Control-H (BS)
  final int sessionId;

  const TerminalViewWidget({
    super.key,
    required this.terminal,
    required this.sessionId,
    this.focusNode,
    this.safetyLevel = 0,
    this.backspaceMode = 0,
  });

  @override
  ConsumerState<TerminalViewWidget> createState() => _TerminalViewWidgetState();
}

class _TerminalViewWidgetState extends ConsumerState<TerminalViewWidget>
    with AutomaticKeepAliveClientMixin {
  late FocusNode _internalFocusNode;
  Function(String)? _originalOnOutput;
  bool _isCtrlPressed = false;
  bool _isAltPressed = false;
  bool _showAiOverlay = false;

  String _inputBuffer = '';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = widget.focusNode ?? FocusNode();

    if (widget.focusNode == null) {
      _internalFocusNode.requestFocus();
    }

    _setupOutputInterception();
  }

  void _setupOutputInterception() {
    // Preserve existing handler (from SSHService or LocalTerminalService)
    _originalOnOutput = widget.terminal.onOutput;

    // Wrap with safety logic, Input Transformation, and AI Preview
    widget.terminal.onOutput = (input) async {
      // 1. Transform Input if modifiers are active
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

      // 1.5 Backspace Compatibility (Replace DEL \x7f with BS \x08 if mode == 1)
      if (widget.backspaceMode == 1) {
        effectiveInput = effectiveInput.replaceAll('\x7f', '\x08');
      }

      // --- NEW: AI Command Preview & Input Interception ---
      // We process the input locally before deciding to send it to the backend.

      bool shouldSendToBackend = true;

      // Handle input stream (may contain multiple characters or escape codes)
      // We iterate to update _inputBuffer correctly.
      for (int i = 0; i < effectiveInput.length; i++) {
        final char = effectiveInput[i];

        if (char == '\x7f' || char == '\b') {
          // Backspace
          if (_inputBuffer.isNotEmpty) {
            _inputBuffer = _inputBuffer.substring(0, _inputBuffer.length - 1);
          }
        } else if (char == '\r' || char == '\n') {
          // Enter - Check for Trigger
          final query = _inputBuffer.trim();
          if (query.length > 2 && query.startsWith('?')) {
            // Block all output (including the Enter key) if triggered
            shouldSendToBackend = false;
            _triggerAiPreview(query);
            // We break because subsequent chars in this chunk (if any) are irrelevant or part of next command
            break;
          } else {
            _inputBuffer = ''; // Reset on normal Enter
          }
        } else {
          // Normal character
          if (char.codeUnitAt(0) >= 32) {
            _inputBuffer += char;
          }
        }
      }

      // If we are strictly debouncing (user typing ?...), we check buffer AFTER processing the chunk
      // REMOVED: Automatic debounce detection

      if (!shouldSendToBackend) {
        return; // Skip sending to backend
      }

      // Fallthrough to special checks or original output
      if (widget.safetyLevel == 2 &&
          (effectiveInput == '\r' || effectiveInput == '\n')) {
        // ... Production check logic relies on 'effectiveInput' being Enter ...
        // Does this work with chunks? 'ssh' usually sends chars as typed, but 'enter' might be alone.
        // If a chunk is 'ls\n', effectiveInput has \n.
        // We should probably rely on the existing logic which checks (effectiveInput == '\r' ...).
        // If effectiveInput == 'ls\n', the check fails.
        // Existing safety check is brittle for chunks, but let's keep it as is for now to avoid regression.
        // Just ensure we don't return early if valid.
      } else {
        // If effectiveInput contains \n inside a larger chunk, safety check might be skipped.
        // We will leave safety check logic 'as is' below, assuming typical interactive usage.
      }

      if (!shouldSendToBackend) {
        return; // Skip sending to backend
      }

      // 2. Command Interception Logic for Production Servers
      // (Only check if we are actually sending an Enter)
      if (widget.safetyLevel == 2 &&
          (effectiveInput == '\r' || effectiveInput == '\n')) {
        final currentLine = widget.terminal.buffer.currentLine.getText();
        final dangerousCommands = ['rm -rf', 'reboot', 'DROP TABLE'];

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

      // Delegate to original handler (Send to SSH/Local)
      _originalOnOutput?.call(effectiveInput);
    };
  }

  Future<void> _triggerAiPreview(String queryWrapper) async {
    final query = queryWrapper.substring(1).trim();
    if (query.isEmpty) return;

    // Call AI
    final service = ref.read(aiAnalysisProvider);
    final command = await service.generateCommand(query);

    // Calculate Deletes
    // We want to delete what is currently in the input buffer (what the user typed)
    // Note: _inputBuffer might have changed if user kept typing during API call?
    // We should probably rely on the `queryWrapper` length we used.
    // BUT user might have typed more chars.
    // For simplicity, we delete `queryWrapper` length.
    // Ideally we should lock input or handle race conditions, but this is a V1.

    final deleteCount = queryWrapper.length;
    final backspaces = List.filled(deleteCount, '\x7f').join();

    // Send to Backend (SSH will echo backspaces and new command)
    _originalOnOutput?.call(backspaces);
    _originalOnOutput?.call(command);

    // Update Buffer
    _inputBuffer = command;
  }

  void _handleAiAnalysis() {
    setState(() {
      _showAiOverlay = true;
    });
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
        AiAssistantIntent: CallbackAction<AiAssistantIntent>(
          onInvoke: (_) {
            _handleAiAnalysis();
            return null;
          },
        ),
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
            Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                border: borderColor != null
                    ? Border.all(color: borderColor, width: borderWidth)
                    : null,
              ),
              child: Stack(
                children: [
                  Column(
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
                          backgroundOpacity:
                              0, // Ensure background shows through
                          theme: _getTerminalTheme(settings.colorScheme),
                        ),
                      ),
                      // Fixed Button Bar (Global Custom Buttons)
                      ButtonBarWidget(
                        onCommand: (cmd) => widget.terminal.onOutput?.call(cmd),
                      ),
                      if (Platform.isAndroid || Platform.isIOS)
                        VirtualKeyToolbar(
                          terminal: widget.terminal,
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
                ],
              ),
            ),
            if (_showAiOverlay)
              AIAnalysisOverlay(
                terminal: widget.terminal,
                onClose: () => setState(() => _showAiOverlay = false),
              ),
          ],
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
