import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../data/security_repository.dart';

class AppLockState {
  final bool isLocked;
  final bool isEnabled;
  final bool isBiometricEnabled;
  final bool hasPin;

  AppLockState({
    required this.isLocked,
    required this.isEnabled,
    required this.isBiometricEnabled,
    required this.hasPin,
  });

  AppLockState copyWith({
    bool? isLocked,
    bool? isEnabled,
    bool? isBiometricEnabled,
    bool? hasPin,
  }) {
    return AppLockState(
      isLocked: isLocked ?? this.isLocked,
      isEnabled: isEnabled ?? this.isEnabled,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      hasPin: hasPin ?? this.hasPin,
    );
  }
}

class AppLockNotifier extends Notifier<AppLockState> {
  late final SecurityRepository _repository;
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  AppLockState build() {
    _repository = ref.watch(securityRepositoryProvider);

    // Initialize with default state
    final initialState = AppLockState(
      isLocked: false,
      isEnabled: false,
      isBiometricEnabled: false,
      hasPin: false,
    );

    // Load actual state asynchronously
    _loadState();

    return initialState;
  }

  Future<void> _loadState() async {
    final isEnabled = await _repository.isAppLockEnabled();
    final isBiometricEnabled = await _repository.isBiometricEnabled();
    final pin = await _repository.getPin();

    state = state.copyWith(
      isEnabled: isEnabled,
      isBiometricEnabled: isBiometricEnabled,
      hasPin: pin != null && pin.isNotEmpty,
      isLocked: isEnabled, // Lock on startup if enabled
    );
  }

  Future<void> setAppLockEnabled(bool enabled) async {
    await _repository.setAppLockEnabled(enabled);
    state = state.copyWith(isEnabled: enabled);
    if (enabled) {
      lock();
    } else {
      unlock();
    }
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _repository.setBiometricEnabled(enabled);
    state = state.copyWith(isBiometricEnabled: enabled);
  }

  Future<void> setPin(String pin) async {
    await _repository.setPin(pin);
    state = state.copyWith(hasPin: true);
  }

  Future<bool> verifyPin(String inputPin) async {
    final storedPin = await _repository.getPin();
    if (storedPin == inputPin) {
      unlock();
      return true;
    }
    return false;
  }

  Future<bool> authenticateBiometric() async {
    if (!state.isBiometricEnabled) return false;

    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) return false;

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to unlock Anter',
      );

      if (didAuthenticate) {
        unlock();
      }
      return didAuthenticate;
    } catch (e) {
      debugPrint('Biometric auth error: $e');
      return false;
    }
  }

  void lock() {
    if (state.isEnabled) {
      state = state.copyWith(isLocked: true);
    }
  }

  void unlock() {
    state = state.copyWith(isLocked: false);
  }
}

final appLockProvider = NotifierProvider<AppLockNotifier, AppLockState>(
  AppLockNotifier.new,
);
