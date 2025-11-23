/// Utility class for executing login scripts
class ScriptExecutor {
  /// Parse and execute a login script
  ///
  /// Supports:
  /// - Regular commands (executed as-is)
  /// - Comments (lines starting with #, ignored unless special)
  /// - Empty lines (ignored)
  /// - Special commands:
  ///   - #WAIT <ms>: Wait for specified milliseconds
  ///   - #DELAY <ms>: Alias for WAIT
  static Stream<ScriptCommand> parse(String script) async* {
    final lines = script.split('\n');

    for (final line in lines) {
      final trimmed = line.trim();

      // Skip empty lines
      if (trimmed.isEmpty) continue;

      // Handle special commands
      if (trimmed.startsWith('#')) {
        // Check for WAIT/DELAY commands
        final waitMatch = RegExp(
          r'^#(WAIT|DELAY)\s+(\d+)',
          caseSensitive: false,
        ).firstMatch(trimmed);

        if (waitMatch != null) {
          final milliseconds = int.parse(waitMatch.group(2)!);
          yield ScriptCommand.wait(Duration(milliseconds: milliseconds));
          continue;
        }

        // Regular comment, skip
        continue;
      }

      // Regular command
      yield ScriptCommand.execute(trimmed);
    }
  }

  /// Execute a script with a callback for each command
  static Future<void> execute(
    String script,
    Future<void> Function(String command) onCommand,
    Future<void> Function(Duration duration) onWait,
  ) async {
    await for (final command in parse(script)) {
      switch (command.type) {
        case ScriptCommandType.execute:
          await onCommand(command.value);
          break;
        case ScriptCommandType.wait:
          await onWait(command.duration!);
          break;
      }
    }
  }

  /// Validate a script and return any errors
  static List<String> validate(String script) {
    final errors = <String>[];
    final lines = script.split('\n');

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty || line.startsWith('#')) {
        // Check for malformed special commands
        if (line.startsWith('#')) {
          final waitMatch = RegExp(
            r'^#(WAIT|DELAY)\s+(\d+)',
            caseSensitive: false,
          ).firstMatch(line);

          if (line.toUpperCase().contains('WAIT') ||
              line.toUpperCase().contains('DELAY')) {
            if (waitMatch == null) {
              errors.add(
                'Line ${i + 1}: Invalid WAIT/DELAY syntax. Use: #WAIT <milliseconds>',
              );
            }
          }
        }
        continue;
      }

      // Validate command is not empty after trimming
      if (line.isEmpty) {
        errors.add('Line ${i + 1}: Empty command');
      }
    }

    return errors;
  }
}

enum ScriptCommandType { execute, wait }

class ScriptCommand {
  final ScriptCommandType type;
  final String value;
  final Duration? duration;

  const ScriptCommand._({required this.type, this.value = '', this.duration});

  factory ScriptCommand.execute(String command) {
    return ScriptCommand._(type: ScriptCommandType.execute, value: command);
  }

  factory ScriptCommand.wait(Duration duration) {
    return ScriptCommand._(type: ScriptCommandType.wait, duration: duration);
  }
}
