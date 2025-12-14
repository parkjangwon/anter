import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SecurityRepository {
  final FlutterSecureStorage _storage;

  SecurityRepository(this._storage);

  static const _pinKey = 'app_lock_pin';
  static const _biometricEnabledKey = 'biometric_enabled';
  static const _appLockEnabledKey = 'app_lock_enabled';

  Future<void> setPin(String pin) async {
    await _storage.write(key: _pinKey, value: pin);
  }

  Future<String?> getPin() async {
    return await _storage.read(key: _pinKey);
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _biometricEnabledKey, value: enabled.toString());
  }

  Future<bool> isBiometricEnabled() async {
    final val = await _storage.read(key: _biometricEnabledKey);
    return val == 'true';
  }

  Future<void> setAppLockEnabled(bool enabled) async {
    await _storage.write(key: _appLockEnabledKey, value: enabled.toString());
  }

  Future<bool> isAppLockEnabled() async {
    final val = await _storage.read(key: _appLockEnabledKey);
    return val == 'true';
  }

  Future<void> clear() async {
    await _storage.deleteAll();
  }
}

final securityRepositoryProvider = Provider<SecurityRepository>((ref) {
  return SecurityRepository(const FlutterSecureStorage());
});
