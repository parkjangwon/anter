import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../application/app_lock_notifier.dart';

class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  String _inputPin = '';
  String? _errorText;

  @override
  void initState() {
    super.initState();
    // Auto-trigger biometrics on load if enabled
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryBiometric();
    });
  }

  Future<void> _tryBiometric() async {
    final notifier = ref.read(appLockProvider.notifier);
    final state = ref.read(appLockProvider);

    if (state.isBiometricEnabled) {
      await notifier.authenticateBiometric();
    }
  }

  void _onKeyPress(String key) {
    if (_inputPin.length < 4) {
      setState(() {
        _inputPin += key;
        _errorText = null;
      });

      if (_inputPin.length == 4) {
        _verifyPin();
      }
    }
  }

  void _onDelete() {
    if (_inputPin.isNotEmpty) {
      setState(() {
        _inputPin = _inputPin.substring(0, _inputPin.length - 1);
        _errorText = null;
      });
    }
  }

  Future<void> _verifyPin() async {
    final success = await ref
        .read(appLockProvider.notifier)
        .verifyPin(_inputPin);

    if (mounted) {
      setState(() {
        if (!success) {
          _inputPin = '';
          _errorText = 'Incorrect PIN';
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final state = ref.watch(appLockProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock, size: 48),
            const SizedBox(height: 24),
            Text(
              'App Locked',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter PIN to unlock',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 32),

            // PIN Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                final isFilled = index < _inputPin.length;
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

            const SizedBox(height: 48),

            // Numpad
            Container(
              constraints: const BoxConstraints(maxWidth: 300),
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
                      state.isBiometricEnabled
                          ? IconButton(
                              onPressed: _tryBiometric,
                              icon: const Icon(Icons.fingerprint, size: 32),
                              color: colorScheme.primary,
                            )
                          : const SizedBox(width: 48),
                      _buildKey('0'),
                      IconButton(
                        onPressed: _onDelete,
                        icon: const Icon(Icons.backspace_outlined),
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
