import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import '../domain/settings_state.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

class SettingsNotifier extends Notifier<SettingsState> {
  static const String _settingsKey = 'app_settings';

  @override
  SettingsState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final settingsJson = prefs.getString(_settingsKey);

    if (settingsJson != null) {
      try {
        final Map<String, dynamic> json = jsonDecode(settingsJson);
        return SettingsState.fromJson(json);
      } catch (e) {
        // If parsing fails, return default settings
        return const SettingsState();
      }
    }

    return const SettingsState();
  }

  Future<void> _saveSettings() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final settingsJson = jsonEncode(state.toJson());
    await prefs.setString(_settingsKey, settingsJson);
  }

  // Terminal Settings
  Future<void> setFontSize(double size) async {
    state = state.copyWith(fontSize: size);
    await _saveSettings();
  }

  Future<void> setFontFamily(String family) async {
    state = state.copyWith(fontFamily: family);
    await _saveSettings();
  }

  Future<void> setCursorStyle(dynamic style) async {
    // Deprecated
  }

  Future<void> setColorScheme(TerminalColorScheme scheme) async {
    state = state.copyWith(colorScheme: scheme);
    await _saveSettings();
  }

  Future<void> setScrollBufferSize(int size) async {
    state = state.copyWith(scrollBufferSize: size);
    await _saveSettings();
  }

  Future<void> setTerminalEncoding(TerminalEncoding encoding) async {
    state = state.copyWith(terminalEncoding: encoding);
    await _saveSettings();
  }

  // Appearance Settings
  Future<void> setWindowOpacity(double opacity) async {
    state = state.copyWith(windowOpacity: opacity);
    await _saveSettings();
    await windowManager.setOpacity(opacity);
  }

  // Behavior Settings
  Future<void> setConfirmOnExit(bool confirm) async {
    state = state.copyWith(confirmOnExit: confirm);
    await _saveSettings();
  }

  Future<void> setAutoReconnect(bool value) async {
    state = state.copyWith(autoReconnect: value);
    await _saveSettings();
  }

  Future<void> setStartupMode(StartupMode mode) async {
    state = state.copyWith(startupMode: mode);
    await _saveSettings();
  }

  // AI Settings
  Future<void> setEnableAiAssistant(bool value) async {
    state = state.copyWith(enableAiAssistant: value);
    await _saveSettings();
  }

  Future<void> setGeminiApiKey(String value) async {
    state = state.copyWith(geminiApiKey: value);
    await _saveSettings();
  }

  Future<void> setGeminiModel(GeminiModel value) async {
    state = state.copyWith(geminiModel: value);
    await _saveSettings();
  }

  Future<void> setAutoRecordSessions(bool value) async {
    state = state.copyWith(autoRecordSessions: value);
    await _saveSettings();
  }

  Future<void> setBellStyle(dynamic style) async {
    // Deprecated
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);
