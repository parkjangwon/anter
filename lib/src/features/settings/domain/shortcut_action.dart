import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum ShortcutCategory {
  application('Application'),
  terminal('Terminal'),
  view('View'),
  split('Split');

  final String label;
  const ShortcutCategory(this.label);
}

enum ShortcutAction {
  // Application
  openSettings('Open Settings', 'settings', ShortcutCategory.application),
  newTab('New Tab', 'new-tab', ShortcutCategory.application),
  closeTab('Close Tab', 'close-tab', ShortcutCategory.application),
  nextTab('Next Tab', 'next-tab', ShortcutCategory.application),
  previousTab('Previous Tab', 'previous-tab', ShortcutCategory.application),
  broadcastInput(
    'Broadcast Input',
    'broadcast-input',
    ShortcutCategory.application,
  ),
  aiAssistant('AI Assistant', 'ai-assistant', ShortcutCategory.application),

  // View
  zoomIn('Zoom In', 'zoom-in', ShortcutCategory.view),
  zoomOut('Zoom Out', 'zoom-out', ShortcutCategory.view),
  resetZoom('Reset Zoom', 'reset-zoom', ShortcutCategory.view);

  final String label;
  final String id;
  final ShortcutCategory category;

  const ShortcutAction(this.label, this.id, this.category);

  static ShortcutActivator? defaultFor(
    ShortcutAction action,
    TargetPlatform platform,
  ) {
    final isMacOS = platform == TargetPlatform.macOS;
    final meta = isMacOS;
    final control = !isMacOS;

    switch (action) {
      case ShortcutAction.openSettings:
        return SingleActivator(
          LogicalKeyboardKey.comma,
          meta: meta,
          control: control,
        );
      case ShortcutAction.newTab:
        return SingleActivator(
          LogicalKeyboardKey.keyT,
          meta: meta,
          control: control,
        );
      case ShortcutAction.closeTab:
        return SingleActivator(
          LogicalKeyboardKey.keyW,
          meta: meta,
          control: control,
        );
      case ShortcutAction.nextTab:
        return SingleActivator(
          LogicalKeyboardKey.tab,
          meta: false,
          control: true,
        );
      case ShortcutAction.previousTab:
        return SingleActivator(
          LogicalKeyboardKey.tab,
          meta: false,
          control: true,
          shift: true,
        );
      case ShortcutAction.zoomIn:
        return SingleActivator(
          LogicalKeyboardKey.equal,
          meta: meta,
          control: control,
        );
      case ShortcutAction.zoomOut:
        return SingleActivator(
          LogicalKeyboardKey.minus,
          meta: meta,
          control: control,
        );
      case ShortcutAction.resetZoom:
        return SingleActivator(
          LogicalKeyboardKey.digit0,
          meta: meta,
          control: control,
        );
      case ShortcutAction.broadcastInput:
        return SingleActivator(
          LogicalKeyboardKey.keyI,
          meta: meta,
          control: control,
          shift: true,
        );
      case ShortcutAction.aiAssistant:
        return SingleActivator(
          LogicalKeyboardKey.keyA,
          meta: meta,
          control: control,
          shift: true,
        );
    }
  }
}

// Helper to serialize/deserialize
class AppShortcutSerialization {
  static Map<String, dynamic> toJson(ShortcutActivator activator) {
    if (activator is SingleActivator) {
      return {
        'keyId': activator.trigger.keyId,
        'control': activator.control,
        'shift': activator.shift,
        'alt': activator.alt,
        'meta': activator.meta,
      };
    }
    return {};
  }

  static ShortcutActivator? fromJson(Map<String, dynamic> json) {
    if (json.isEmpty) return null;
    return SingleActivator(
      LogicalKeyboardKey.findKeyByKeyId(json['keyId'] as int) ??
          LogicalKeyboardKey.keyA, // Fallback
      control: json['control'] as bool? ?? false,
      shift: json['shift'] as bool? ?? false,
      alt: json['alt'] as bool? ?? false,
      meta: json['meta'] as bool? ?? false,
    );
  }

  static String toStringDisplay(ShortcutActivator activator) {
    if (activator is SingleActivator) {
      final parts = <String>[];
      if (activator.meta) parts.add('Cmd');
      if (activator.control) parts.add('Ctrl');
      if (activator.alt) parts.add('Alt');
      if (activator.shift) parts.add('Shift');

      // Special key labels
      String keyLabel = activator.trigger.keyLabel;
      if (activator.trigger == LogicalKeyboardKey.arrowUp) keyLabel = 'Up';
      if (activator.trigger == LogicalKeyboardKey.arrowDown) keyLabel = 'Down';
      if (activator.trigger == LogicalKeyboardKey.arrowLeft) keyLabel = 'Left';
      if (activator.trigger == LogicalKeyboardKey.arrowRight)
        keyLabel = 'Right';
      if (activator.trigger == LogicalKeyboardKey.enter) keyLabel = 'Enter';
      if (activator.trigger == LogicalKeyboardKey.escape) keyLabel = 'Esc';
      if (activator.trigger == LogicalKeyboardKey.backspace)
        keyLabel = 'Backspace';
      if (activator.trigger == LogicalKeyboardKey.delete) keyLabel = 'Delete';
      if (activator.trigger == LogicalKeyboardKey.tab) keyLabel = 'Tab';
      if (activator.trigger == LogicalKeyboardKey.space) keyLabel = 'Space';

      parts.add(keyLabel.toUpperCase());
      return parts.join('+');
    }
    return 'Unknown';
  }
}
