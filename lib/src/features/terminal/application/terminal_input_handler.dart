class KeyModifierHandler {
  static String transformInput(
    String input, {
    bool isCtrl = false,
    bool isAlt = false,
  }) {
    String result = input;

    if (input.length == 1) {
      if (isCtrl) {
        final codeUnit = input.codeUnitAt(0);
        // Handle lowercase a-z (97-122)
        if (codeUnit >= 97 && codeUnit <= 122) {
          result = String.fromCharCode(codeUnit - 96);
        }
        // Handle uppercase A-Z (65-90) - treat same as lowercase for Ctrl
        else if (codeUnit >= 65 && codeUnit <= 90) {
          result = String.fromCharCode(codeUnit - 64);
        }
        // Additional widely used control codes can be added here
        // For example: [, \, ], ^, _
      }

      if (isAlt) {
        // Prepend Escape
        result = '\x1b$result';
      }
    }

    return result;
  }
}
