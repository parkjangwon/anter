import 'dart:convert';
import 'dart:io';

import 'package:flutter_pty/flutter_pty.dart';
import 'package:xterm/xterm.dart';

class LocalTerminalService {
  Pty? _pty;

  Future<void> start(Terminal terminal) async {
    try {
      final shell = Platform.isWindows ? 'cmd.exe' : '/bin/zsh';

      _pty = Pty.start(
        shell,
        columns: terminal.viewWidth,
        rows: terminal.viewHeight,
      );

      // Pipe pty output to terminal
      _pty!.output.listen((data) {
        terminal.write(utf8.decode(data));
      });

      // Pipe terminal input to pty
      terminal.onOutput = (data) {
        _pty!.write(utf8.encode(data));
      };

      terminal.onResize = (w, h, pw, ph) {
        _pty!.resize(h, w);
      };
    } catch (e) {
      terminal.write('Failed to start local shell: $e\r\n');
    }
  }

  void dispose() {
    _pty?.kill();
  }
}
