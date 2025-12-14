import 'package:flutter_test/flutter_test.dart';
import 'package:anter/src/features/terminal/application/terminal_input_handler.dart';

void main() {
  group('KeyModifierHandler', () {
    test('transformInput passes through normal text', () {
      expect(KeyModifierHandler.transformInput('a'), 'a');
      expect(KeyModifierHandler.transformInput('Z'), 'Z');
      expect(KeyModifierHandler.transformInput('1'), '1');
    });

    test('transformInput handles Ctrl modifier for lowercase', () {
      // Ctrl+a -> \x01
      expect(KeyModifierHandler.transformInput('a', isCtrl: true), '\x01');
      // Ctrl+c -> \x03
      expect(KeyModifierHandler.transformInput('c', isCtrl: true), '\x03');
      // Ctrl+z -> \x1a
      expect(KeyModifierHandler.transformInput('z', isCtrl: true), '\x1a');
    });

    test('transformInput handles Ctrl modifier for uppercase', () {
      // Ctrl+A -> \x01
      expect(KeyModifierHandler.transformInput('A', isCtrl: true), '\x01');
      // Ctrl+C -> \x03
      expect(KeyModifierHandler.transformInput('C', isCtrl: true), '\x03');
    });

    test('transformInput handles Alt modifier', () {
      expect(KeyModifierHandler.transformInput('a', isAlt: true), '\x1ba');
      expect(KeyModifierHandler.transformInput('X', isAlt: true), '\x1bX');
    });

    test('transformInput handles Ctrl+Alt modifier', () {
      // Should result in Esc + ControlCode
      expect(
        KeyModifierHandler.transformInput('c', isCtrl: true, isAlt: true),
        '\x1b\x03',
      );
    });

    test(
      'transformInput ignores Ctrl for non-alpha keys (basic implementation)',
      () {
        // Current implementation only transforms A-Z/a-z.
        // Ensure other keys are passed through or handled as expected.
        expect(KeyModifierHandler.transformInput('1', isCtrl: true), '1');
      },
    );
  });
}
