import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:xterm/xterm.dart';
import '../../../settings/presentation/settings_provider.dart';
import '../../../settings/domain/settings_state.dart';
import '../../../settings/domain/shortcut_intents.dart';
import '../../../../core/theme/terminal_themes.dart' as app_theme;

class TerminalViewWidget extends ConsumerStatefulWidget {
  final Terminal terminal;
  final void Function(String) onInput;
  final FocusNode? focusNode;

  const TerminalViewWidget({
    super.key,
    required this.terminal,
    required this.onInput,
    this.focusNode,
  });

  @override
  ConsumerState<TerminalViewWidget> createState() => _TerminalViewWidgetState();
}

class _TerminalViewWidgetState extends ConsumerState<TerminalViewWidget>
    with AutomaticKeepAliveClientMixin {
  late FocusNode _internalFocusNode;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = widget.focusNode ?? FocusNode();

    if (widget.focusNode == null) {
      _internalFocusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _internalFocusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin
    final settings = ref.watch(settingsProvider);

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
        child: TerminalView(
          widget.terminal,
          textStyle: TerminalStyle(
            fontSize: settings.fontSize,
            fontFamily: settings.fontFamily,
          ),
          autofocus: true,
          focusNode: _internalFocusNode,
          backgroundOpacity: 0,
          theme: _getTerminalTheme(settings.colorScheme),
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
