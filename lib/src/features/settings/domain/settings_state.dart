import 'package:flutter/material.dart';

/// Comprehensive settings state for the Anter SSH client
class SettingsState {
  // Terminal Settings
  final double fontSize;
  final String fontFamily;
  final TerminalColorScheme colorScheme;
  final int scrollBufferSize;
  final TerminalEncoding terminalEncoding;

  // Appearance Settings
  final ThemeMode themeMode;
  final double windowOpacity;

  // Behavior Settings
  final bool confirmOnExit;
  final bool autoReconnect;
  final StartupMode startupMode;

  // AI Settings
  final bool enableAiAssistant;
  final String geminiApiKey;
  final GeminiModel geminiModel;

  // Recording Settings
  final bool autoRecordSessions;

  const SettingsState({
    // Terminal defaults
    this.fontSize = 14.0,
    this.fontFamily = 'MesloLGS NF',
    this.colorScheme = TerminalColorScheme.dracula,
    this.scrollBufferSize = 1000,
    this.terminalEncoding = TerminalEncoding.utf8,

    // Appearance defaults
    this.themeMode = ThemeMode.system,
    this.windowOpacity = 1.0,

    // Behavior defaults
    this.confirmOnExit = true,
    this.autoReconnect = false,
    this.startupMode = StartupMode.sessionList,

    // AI defaults
    this.enableAiAssistant = false,
    this.geminiApiKey = '',
    this.geminiModel = GeminiModel.geminiFlashLite,

    // Recording defaults
    this.autoRecordSessions = false,
  });

  SettingsState copyWith({
    double? fontSize,
    String? fontFamily,
    TerminalColorScheme? colorScheme,
    int? scrollBufferSize,
    TerminalEncoding? terminalEncoding,
    ThemeMode? themeMode,
    double? windowOpacity,
    bool? confirmOnExit,
    bool? autoReconnect,
    StartupMode? startupMode,
    bool? enableAiAssistant,
    String? geminiApiKey,
    GeminiModel? geminiModel,
    bool? autoRecordSessions,
  }) {
    return SettingsState(
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      colorScheme: colorScheme ?? this.colorScheme,
      scrollBufferSize: scrollBufferSize ?? this.scrollBufferSize,
      terminalEncoding: terminalEncoding ?? this.terminalEncoding,
      themeMode: themeMode ?? this.themeMode,
      windowOpacity: windowOpacity ?? this.windowOpacity,
      confirmOnExit: confirmOnExit ?? this.confirmOnExit,
      autoReconnect: autoReconnect ?? this.autoReconnect,
      startupMode: startupMode ?? this.startupMode,
      enableAiAssistant: enableAiAssistant ?? this.enableAiAssistant,
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
      geminiModel: geminiModel ?? this.geminiModel,
      autoRecordSessions: autoRecordSessions ?? this.autoRecordSessions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fontSize': fontSize,
      'fontFamily': fontFamily,
      'colorScheme': colorScheme.name,
      'scrollBufferSize': scrollBufferSize,
      'terminalEncoding': terminalEncoding.name,
      'themeMode': themeMode.name,
      'windowOpacity': windowOpacity,
      'confirmOnExit': confirmOnExit,
      'autoReconnect': autoReconnect,
      'startupMode': startupMode.name,
      'enableAiAssistant': enableAiAssistant,
      'geminiApiKey': geminiApiKey,
      'geminiModel': geminiModel.name,
      'autoRecordSessions': autoRecordSessions,
    };
  }

  factory SettingsState.fromJson(Map<String, dynamic> json) {
    return SettingsState(
      fontSize: json['fontSize'] as double? ?? 14.0,
      fontFamily: json['fontFamily'] as String? ?? 'MesloLGS NF',
      colorScheme: TerminalColorScheme.values.firstWhere(
        (e) => e.name == json['colorScheme'],
        orElse: () => TerminalColorScheme.dracula,
      ),
      scrollBufferSize: json['scrollBufferSize'] as int? ?? 1000,
      terminalEncoding: TerminalEncoding.values.firstWhere(
        (e) => e.name == json['terminalEncoding'],
        orElse: () => TerminalEncoding.utf8,
      ),
      themeMode: ThemeMode.values.firstWhere(
        (e) => e.name == json['themeMode'],
        orElse: () => ThemeMode.system,
      ),
      windowOpacity: json['windowOpacity'] as double? ?? 1.0,
      confirmOnExit: json['confirmOnExit'] as bool? ?? true,
      autoReconnect: json['autoReconnect'] as bool? ?? false,
      startupMode: StartupMode.values.firstWhere(
        (e) => e.name == json['startupMode'],
        orElse: () => StartupMode.sessionList,
      ),
      enableAiAssistant: json['enableAiAssistant'] as bool? ?? false,
      geminiApiKey: json['geminiApiKey'] as String? ?? '',
      geminiModel: GeminiModel.values.firstWhere(
        (e) => e.name == json['geminiModel'],
        orElse: () => GeminiModel.geminiFlashLite,
      ),
      autoRecordSessions: json['autoRecordSessions'] as bool? ?? false,
    );
  }
}

enum StartupMode { sessionList, localTerminal }

enum GeminiModel { geminiPro, geminiFlash, geminiFlashLite }

extension GeminiModelExtension on GeminiModel {
  String get displayName {
    switch (this) {
      case GeminiModel.geminiPro:
        return 'Gemini 2.5 Pro';
      case GeminiModel.geminiFlash:
        return 'Gemini 2.5 Flash';
      case GeminiModel.geminiFlashLite:
        return 'Gemini 2.5 Flash Lite';
    }
  }

  String get modelId {
    switch (this) {
      case GeminiModel.geminiPro:
        return 'gemini-2.5-pro';
      case GeminiModel.geminiFlash:
        return 'gemini-2.5-flash';
      case GeminiModel.geminiFlashLite:
        return 'gemini-2.5-flash-lite';
    }
  }
}

enum TerminalEncoding { utf8, eucKr, shiftJis, iso88591, gb2312, big5 }

extension TerminalEncodingExtension on TerminalEncoding {
  String get displayName {
    switch (this) {
      case TerminalEncoding.utf8:
        return 'UTF-8';
      case TerminalEncoding.eucKr:
        return 'EUC-KR (Korean)';
      case TerminalEncoding.shiftJis:
        return 'Shift-JIS (Japanese)';
      case TerminalEncoding.iso88591:
        return 'ISO-8859-1 (Latin-1)';
      case TerminalEncoding.gb2312:
        return 'GB2312 (Simplified Chinese)';
      case TerminalEncoding.big5:
        return 'Big5 (Traditional Chinese)';
    }
  }

  String get charsetName {
    switch (this) {
      case TerminalEncoding.utf8:
        return 'utf-8';
      case TerminalEncoding.eucKr:
        return 'euc-kr';
      case TerminalEncoding.shiftJis:
        return 'shift_jis';
      case TerminalEncoding.iso88591:
        return 'iso-8859-1';
      case TerminalEncoding.gb2312:
        return 'gb2312';
      case TerminalEncoding.big5:
        return 'big5';
    }
  }
}

enum TerminalColorScheme {
  dracula,
  monokai,
  solarizedDark,
  solarizedLight,
  gruvboxDark,
  gruvboxLight,
  nord,
  oneDark,
  oneLight,
}

extension TerminalColorSchemeExtension on TerminalColorScheme {
  String get displayName {
    switch (this) {
      case TerminalColorScheme.dracula:
        return 'Dracula';
      case TerminalColorScheme.monokai:
        return 'Monokai';
      case TerminalColorScheme.solarizedDark:
        return 'Solarized Dark';
      case TerminalColorScheme.solarizedLight:
        return 'Solarized Light';
      case TerminalColorScheme.gruvboxDark:
        return 'Gruvbox Dark';
      case TerminalColorScheme.gruvboxLight:
        return 'Gruvbox Light';
      case TerminalColorScheme.nord:
        return 'Nord';
      case TerminalColorScheme.oneDark:
        return 'One Dark';
      case TerminalColorScheme.oneLight:
        return 'One Light';
    }
  }
}
