import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:xterm/xterm.dart';

class VirtualKeyToolbar extends StatelessWidget {
  final Terminal terminal;

  const VirtualKeyToolbar({super.key, required this.terminal});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor, width: 0.5),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        children: [
          _VirtualKey(
            label: 'Esc',
            onTap: () => terminal.keyInput(TerminalKey.escape),
          ),
          _VirtualKey(
            label: 'Tab',
            onTap: () => terminal.keyInput(TerminalKey.tab),
          ),
          _VirtualKey(
            label: 'Ctrl+C',
            onTap: () => terminal.onOutput?.call('\x03'),
          ),
          _VirtualKey(
            label: 'Ctrl+Z',
            onTap: () => terminal.onOutput?.call('\x1a'),
          ),
          _VirtualKey(
            label: 'Ctrl+D',
            onTap: () => terminal.onOutput?.call('\x04'),
          ),
          const VerticalDivider(width: 8, indent: 8, endIndent: 8),
          _VirtualKey(
            icon: Icons.arrow_upward,
            onTap: () => terminal.keyInput(TerminalKey.arrowUp),
          ),
          _VirtualKey(
            icon: Icons.arrow_downward,
            onTap: () => terminal.keyInput(TerminalKey.arrowDown),
          ),
          _VirtualKey(
            icon: Icons.arrow_back,
            onTap: () => terminal.keyInput(TerminalKey.arrowLeft),
          ),
          _VirtualKey(
            icon: Icons.arrow_forward,
            onTap: () => terminal.keyInput(TerminalKey.arrowRight),
          ),
          const VerticalDivider(width: 8, indent: 8, endIndent: 8),
          _VirtualKey(label: '/', onTap: () => terminal.textInput('/')),
          _VirtualKey(label: ':', onTap: () => terminal.textInput(':')),
          _VirtualKey(label: '-', onTap: () => terminal.textInput('-')),
          _VirtualKey(label: '|', onTap: () => terminal.textInput('|')),
          _VirtualKey(label: '~', onTap: () => terminal.textInput('~')),
          _VirtualKey(label: '"', onTap: () => terminal.textInput('"')),
          _VirtualKey(label: "'", onTap: () => terminal.textInput("'")),
        ],
      ),
    );
  }
}

class _VirtualKey extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;

  const _VirtualKey({this.label, this.icon, required this.onTap})
    : assert(label != null || icon != null);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(4),
        child: Container(
          constraints: const BoxConstraints(minWidth: 40),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.center,
          child: icon != null
              ? Icon(icon, size: 18)
              : Text(
                  label!,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
        ),
      ),
    );
  }
}
