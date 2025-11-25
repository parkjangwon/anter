import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/shortcut_action.dart';
import 'settings_provider.dart'; // For sharedPreferencesProvider

class ShortcutsNotifier
    extends Notifier<Map<ShortcutAction, List<ShortcutActivator>>> {
  static const String _shortcutsKey = 'app_shortcuts';

  @override
  Map<ShortcutAction, List<ShortcutActivator>> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final shortcutsJson = prefs.getString(_shortcutsKey);

    Map<ShortcutAction, List<ShortcutActivator>> shortcuts = {};

    // Initialize with defaults
    final platform = defaultTargetPlatform;

    for (final action in ShortcutAction.values) {
      final defaultActivator = ShortcutAction.defaultFor(action, platform);
      if (defaultActivator != null) {
        shortcuts[action] = [defaultActivator];
      } else {
        shortcuts[action] = [];
      }
    }

    if (shortcutsJson != null) {
      try {
        final Map<String, dynamic> json = jsonDecode(shortcutsJson);
        json.forEach((key, value) {
          final action = ShortcutAction.values.firstWhere(
            (e) => e.id == key,
            orElse: () => ShortcutAction.openSettings, // Fallback
          );

          // If key matches an action
          if (action.id == key) {
            final List<dynamic> activatorsJson = value as List<dynamic>;
            final List<ShortcutActivator> activators = [];
            for (final item in activatorsJson) {
              final activator = AppShortcutSerialization.fromJson(
                item as Map<String, dynamic>,
              );
              if (activator != null) {
                activators.add(activator);
              }
            }
            shortcuts[action] = activators;
          }
        });
      } catch (e) {
        debugPrint('Error loading shortcuts: $e');
      }
    }

    return shortcuts;
  }

  Future<void> _saveShortcuts() async {
    final prefs = ref.read(sharedPreferencesProvider);
    final Map<String, dynamic> json = {};

    state.forEach((action, activators) {
      json[action.id] = activators
          .map((a) => AppShortcutSerialization.toJson(a))
          .toList();
    });

    await prefs.setString(_shortcutsKey, jsonEncode(json));
  }

  Future<void> addShortcut(
    ShortcutAction action,
    ShortcutActivator activator,
  ) async {
    final currentList = state[action] ?? [];
    // Avoid duplicates
    if (currentList.any((a) => _areActivatorsEqual(a, activator))) {
      return;
    }

    final newList = [...currentList, activator];
    state = {...state, action: newList};
    await _saveShortcuts();
  }

  Future<void> removeShortcut(
    ShortcutAction action,
    ShortcutActivator activator,
  ) async {
    final currentList = state[action] ?? [];
    final newList = currentList
        .where((a) => !_areActivatorsEqual(a, activator))
        .toList();
    state = {...state, action: newList};
    await _saveShortcuts();
  }

  Future<void> resetToDefaults() async {
    final platform = defaultTargetPlatform;
    Map<ShortcutAction, List<ShortcutActivator>> shortcuts = {};
    for (final action in ShortcutAction.values) {
      final defaultActivator = ShortcutAction.defaultFor(action, platform);
      if (defaultActivator != null) {
        shortcuts[action] = [defaultActivator];
      } else {
        shortcuts[action] = [];
      }
    }
    state = shortcuts;
    await _saveShortcuts();
  }

  bool _areActivatorsEqual(ShortcutActivator a, ShortcutActivator b) {
    if (a is SingleActivator && b is SingleActivator) {
      return a.trigger == b.trigger &&
          a.control == b.control &&
          a.shift == b.shift &&
          a.alt == b.alt &&
          a.meta == b.meta;
    }
    return false;
  }
}

final shortcutsProvider =
    NotifierProvider<
      ShortcutsNotifier,
      Map<ShortcutAction, List<ShortcutActivator>>
    >(ShortcutsNotifier.new);
