import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../application/app_lock_notifier.dart';

class PinSetupScreen extends ConsumerStatefulWidget {
  final bool isChangeMode;

  const PinSetupScreen({super.key, this.isChangeMode = false});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  String _pin = '';
  String? _firstPin;
  String _title = 'Create PIN';
  String? _errorText;

  @override
  void initState() {
    super.initState();
    if (widget.isChangeMode) {
      _title = 'Enter Old PIN';
    }
  }

  void _onKeyPress(String key) {
    if (_pin.length < 4) {
      setState(() {
        _pin += key;
        _errorText = null;
      });

      if (_pin.length == 4) {
        _handlePinComplete();
      }
    }
  }

  void _onDelete() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _errorText = null;
      });
    }
  }

  Future<void> _handlePinComplete() async {
    final notifier = ref.read(appLockProvider.notifier);

    if (widget.isChangeMode) {
      // Step 1: Verify Old PIN
      if (_title == 'Enter Old PIN') {
        final isValid = await notifier.verifyPin(_pin);
        if (isValid) {
          setState(() {
            _pin = '';
            _title = 'Enter New PIN';
            _errorText = null;
          });
        } else {
          setState(() {
            _pin = '';
            _errorText = 'Incorrect Old PIN';
          });
        }
        return;
      }
    }

    // Create/Change PIN Mode (New PIN entry)
    if (_firstPin == null) {
      // First entry
      setState(() {
        _firstPin = _pin;
        _pin = '';
        _title = 'Confirm PIN';
        _errorText = null;
      });
    } else {
      // Confirmation
      if (_pin == _firstPin) {
        await notifier.setPin(_pin);
        await notifier.setAppLockEnabled(true); // Auto-enable if setting up
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('PIN Set Successfully')));
        }
      } else {
        setState(() {
          _pin = '';
          _firstPin = null;
          _title = widget.isChangeMode ? 'Enter New PIN' : 'Create PIN';
          _errorText = 'PINs do not match. Try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isChangeMode ? 'Change PIN' : 'Setup App Lock'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 1),
            Text(
              _title,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),

            // PIN Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < _pin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFilled
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerHighest,
                    border: isFilled
                        ? null
                        : Border.all(color: colorScheme.outline),
                  ),
                );
              }),
            ),

            if (_errorText != null) ...[
              const SizedBox(height: 16),
              Text(_errorText!, style: TextStyle(color: colorScheme.error)),
            ],

            const Spacer(flex: 2),

            // Numpad
            Container(
              constraints: const BoxConstraints(maxWidth: 300),
              padding: const EdgeInsets.only(bottom: 32),
              child: Column(
                children: [
                  _buildRow(['1', '2', '3']),
                  const SizedBox(height: 24),
                  _buildRow(['4', '5', '6']),
                  const SizedBox(height: 24),
                  _buildRow(['7', '8', '9']),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const SizedBox(width: 64), // Placeholder for alignment
                      _buildKey('0'),
                      IconButton(
                        onPressed: _onDelete,
                        icon: const Icon(Icons.backspace_outlined),
                        iconSize: 28,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) => _buildKey(key)).toList(),
    );
  }

  Widget _buildKey(String key) {
    return InkWell(
      onTap: () => _onKeyPress(key),
      customBorder: const CircleBorder(),
      child: Container(
        width: 64,
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: Text(
          key,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
