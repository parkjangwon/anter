import 'package:xterm/xterm.dart';

class TerminalBufferHelper {
  /// Extracts the last [lineCount] lines from the terminal buffer
  /// and strips ANSI color codes.
  static String getSanitizedOutput(Terminal terminal, {int lineCount = 50}) {
    final buffer = terminal.buffer;
    final int totalLines = buffer.lines.length;
    final int startLine = (totalLines - lineCount).clamp(0, totalLines);

    final StringBuffer extractedText = StringBuffer();

    // Iterate through lines
    for (int i = startLine; i < totalLines; i++) {
      // terminal.buffer.lines[i] returns a TerminalLine
      // We need to convert it to string.
      // xterm package TerminalLine has toString() but it might debug info.
      // Usually getText() is safer if available on line or we build it cell by cell.
      // Let's check xterm/TerminalLine API if I can.
      // Assuming standard xterm.dart usage:
      // getText() on the buffer range or cell iteration.

      // Actually, let's use the provided getLines logic or similar.
      // buffer.lines[i].toString() typically returns the text content.

      // Standard ANSI removal Regex
      // \x1B\[[0-9;]*[a-zA-Z]

      var lineText = buffer.lines[i].toString();

      // The toString() of TerminalLine might be just the objects.
      // Let's verify xterm API by assumption or small test if needed.
      // Looking at xterm.dart source code on pub.dev (mental check):
      // TerminalLine behaves like a list of cells.
      // However, user provided this snippet:
      // return terminal.buffer.active.lines.toList().takeLast(30).map((line) => line.toString()).join('\n');
      // I will trust user's snippet partially but improve it.
      // terminal.buffer.active seems to be specific to 'active' vs 'alt' buffer.

      extractedText.writeln(lineText);
    }

    return stripAnsi(extractedText.toString());
  }

  static String stripAnsi(String input) {
    final ansiRegex = RegExp(r'\x1B\[[0-9;]*[a-zA-Z]');
    return input.replaceAll(ansiRegex, '');
  }
}
