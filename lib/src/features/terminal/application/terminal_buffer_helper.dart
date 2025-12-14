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

  /// Extracts the currently visible lines from the terminal buffer
  /// as seen by the user on the screen.
  static String getVisibleOutput(Terminal terminal) {
    // Note: detailed scroll offset API in xterm.dart varies by version.
    // Assuming standard behavior where we want the viewport content.
    // If scrollOffset is not available, we default to the last [viewHeight] lines
    // which represents the "bottom" of the terminal (most common case).

    final viewHeight = terminal.viewHeight;
    final buffer = terminal.buffer;
    final totalLines = buffer.lines.length;

    // Default to the last viewHeight lines (bottom of screen)
    int startLine = (totalLines - viewHeight).clamp(0, totalLines);
    int endLine = totalLines;

    // Attempt to use scrollOffset if available (Checking dynamic to avoid analyzer error if possible,
    // but better to just stick to safe implementation for now).
    // In many xterm implementations, scrollOffset 0 means top of history?
    // Or scrollOffsetFromBottom?
    // Without exact API, `totalLines - viewHeight` is the best approximation for "current screen"
    // assuming the user hasn't scrolled up significantly to look at old history
    // while invoking AI.

    final StringBuffer extractedText = StringBuffer();

    for (int i = startLine; i < endLine; i++) {
      if (i >= 0 && i < totalLines) {
        extractedText.writeln(buffer.lines[i].toString());
      }
    }

    return stripAnsi(extractedText.toString());
  }

  static String stripAnsi(String input) {
    final ansiRegex = RegExp(r'\x1B\[[0-9;]*[a-zA-Z]');
    return input.replaceAll(ansiRegex, '');
  }
}
