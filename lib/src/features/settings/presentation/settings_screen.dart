import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme_provider.dart';
import 'settings_provider.dart';
import '../domain/settings_state.dart';
import '../domain/shortcut_intents.dart';
import '../application/backup_service.dart';
import 'widgets/shortcut_settings_section.dart';
import '../../security/application/app_lock_notifier.dart';
import '../../security/presentation/pin_setup_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Auto-focus search field when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMacOS = Theme.of(context).platform == TargetPlatform.macOS;

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
          return KeyEventResult.ignored;
        }

        final isControlPressed = HardwareKeyboard.instance.isControlPressed;
        final isMetaPressed = HardwareKeyboard.instance.isMetaPressed;
        final modifierPressed = isMacOS ? isMetaPressed : isControlPressed;

        // Close settings: Cmd+W / Ctrl+W
        if (event.logicalKey == LogicalKeyboardKey.keyW && modifierPressed) {
          Navigator.of(context).pop();
          return KeyEventResult.handled;
        }

        return KeyEventResult.ignored;
      },
      child: Actions(
        actions: {
          OpenSettingsIntent: CallbackAction<OpenSettingsIntent>(
            onInvoke: (_) => null, // Do nothing if already in settings
          ),
        },
        child: Scaffold(
          body: Column(
            children: [
              if (isMacOS) const SizedBox(height: 28),
              // Header with search
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 600;
                    return Container(
                      padding: EdgeInsets.all(isNarrow ? 8 : 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        border: Border(
                          bottom: BorderSide(
                            color: Theme.of(context).dividerColor,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back),
                            onPressed: () => Navigator.of(context).pop(),
                            padding: EdgeInsets.all(isNarrow ? 8 : 12),
                            constraints: const BoxConstraints(),
                          ),
                          SizedBox(width: isNarrow ? 8 : 16),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              decoration: InputDecoration(
                                hintText: isNarrow
                                    ? 'Search...'
                                    : 'Search settings...',
                                prefixIcon: const Icon(Icons.search, size: 20),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 20),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                      )
                                    : null,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: isNarrow ? 8 : 12,
                                  vertical: isNarrow ? 6 : 8,
                                ),
                                isDense: true,
                              ),
                              onChanged: (value) {
                                setState(
                                  () => _searchQuery = value.toLowerCase(),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              // Settings content
              Expanded(child: _SettingsContent(searchQuery: _searchQuery)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsContent extends ConsumerWidget {
  final String searchQuery;

  const _SettingsContent({required this.searchQuery});

  bool _matchesSearch(String text) {
    if (searchQuery.isEmpty) return true;
    return text.toLowerCase().contains(searchQuery);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final themeMode = ref.watch(themeModeControllerProvider);

    final sections = <Widget>[];

    // Terminal Section
    if (_matchesSearch('terminal') ||
        _matchesSearch('font') ||
        _matchesSearch('color') ||
        _matchesSearch('encoding') ||
        _matchesSearch('buffer')) {
      sections.add(
        _buildSection(context, 'Terminal', Icons.terminal, [
          if (_matchesSearch('font size'))
            _buildSliderSetting(
              'Font Size',
              '${settings.fontSize.toInt()} px',
              settings.fontSize,
              8.0,
              32.0,
              24,
              (value) => notifier.setFontSize(value),
            ),
          if (_matchesSearch('font family'))
            _buildDropdownSetting<String>(
              'Font Family',
              settings.fontFamily,
              const [
                ('monospace', 'Monospace'),
                ('MesloLGS NF', 'MesloLGS NF'),
                ('JetBrains Mono', 'JetBrains Mono'),
                ('Fira Code', 'Fira Code'),
                ('Courier New', 'Courier New'),
              ],
              (value) => notifier.setFontFamily(value),
            ),
          if (_matchesSearch('color scheme'))
            _buildColorSchemeSetting(settings, notifier),
          if (_matchesSearch('encoding'))
            _buildDropdownSetting<TerminalEncoding>(
              'Terminal Encoding',
              settings.terminalEncoding,
              TerminalEncoding.values.map((e) => (e, e.displayName)).toList(),
              (value) => notifier.setTerminalEncoding(value),
            ),
          if (_matchesSearch('scroll buffer'))
            _buildSliderSetting(
              'Scroll Buffer Size',
              '${settings.scrollBufferSize} lines',
              settings.scrollBufferSize.toDouble(),
              100,
              10000,
              99,
              (value) => notifier.setScrollBufferSize(value.toInt()),
            ),
        ]),
      );
    }

    // Appearance Section
    if (_matchesSearch('appearance') ||
        _matchesSearch('theme') ||
        _matchesSearch('opacity') ||
        _matchesSearch('window')) {
      sections.add(
        _buildSection(context, 'Appearance', Icons.palette, [
          if (_matchesSearch('theme mode'))
            _buildDropdownSetting<ThemeMode>(
              'Theme Mode',
              themeMode,
              const [
                (ThemeMode.system, 'System'),
                (ThemeMode.light, 'Light'),
                (ThemeMode.dark, 'Dark'),
              ],
              (mode) => ref
                  .read(themeModeControllerProvider.notifier)
                  .setThemeMode(mode),
            ),
          if (_matchesSearch('window opacity'))
            _buildSliderSetting(
              'Window Opacity',
              '${(settings.windowOpacity * 100).toInt()}%',
              settings.windowOpacity,
              0.5,
              1.0,
              10,
              (value) => notifier.setWindowOpacity(value),
            ),
        ]),
      );
    }

    // Behavior Section
    if (_matchesSearch('behavior') ||
        _matchesSearch('confirm') ||
        _matchesSearch('reconnect') ||
        _matchesSearch('startup')) {
      sections.add(
        _buildSection(context, 'Behavior', Icons.settings, [
          if (_matchesSearch('confirm on exit'))
            _buildSwitchSetting(
              'Confirm on Exit',
              'Show confirmation dialog when closing the app',
              settings.confirmOnExit,
              (value) => notifier.setConfirmOnExit(value),
            ),
          if (_matchesSearch('auto reconnect'))
            _buildSwitchSetting(
              'Auto Reconnect',
              'Automatically reconnect on connection loss',
              settings.autoReconnect,
              (value) => notifier.setAutoReconnect(value),
            ),
          if (_matchesSearch('auto record'))
            _buildSwitchSetting(
              'Auto Record Sessions',
              'Automatically record all session outputs for replay',
              settings.autoRecordSessions,
              (value) => notifier.setAutoRecordSessions(value),
            ),
          if (_matchesSearch('startup mode'))
            Builder(
              builder: (context) {
                final platform = Theme.of(context).platform;
                final isMobile =
                    platform == TargetPlatform.android ||
                    platform == TargetPlatform.iOS;

                // Filter startup modes based on platform
                final availableModes = isMobile
                    ? [(StartupMode.sessionList, 'Session List')]
                    : [
                        (StartupMode.sessionList, 'Session List'),
                        (StartupMode.localTerminal, 'Local Terminal'),
                      ];

                return _buildDropdownSetting<StartupMode>(
                  'Startup Mode',
                  settings.startupMode,
                  availableModes,
                  (mode) => notifier.setStartupMode(mode),
                  subtitle: 'Choose what to show when the app starts',
                );
              },
            ),
        ]),
      );
    }

    // AI Assistant Section
    if (_matchesSearch('ai') ||
        _matchesSearch('assistant') ||
        _matchesSearch('gemini') ||
        _matchesSearch('model')) {
      sections.add(
        _buildSection(context, 'AI Assistant', Icons.auto_awesome, [
          _buildSwitchSetting(
            'Enable Gemini Assistant',
            'Use Google Gemini AI to generate Linux commands',
            settings.enableAiAssistant,
            (value) {
              notifier.setEnableAiAssistant(value);
            },
          ),
          if (settings.enableAiAssistant) ...[
            const Divider(),
            _buildTextFieldSetting(
              'Gemini API Key',
              settings.geminiApiKey,
              (value) => notifier.setGeminiApiKey(value),
              obscureText: true,
              hintText: 'Enter your Gemini API Key',
            ),
            const SizedBox(height: 8),
            _buildDropdownSetting<GeminiModel>(
              'Gemini Model',
              settings.geminiModel,
              GeminiModel.values.map((e) => (e, e.displayName)).toList(),
              (value) => notifier.setGeminiModel(value),
            ),
          ],
        ]),
      );
    }

    // Shortcuts Section
    if (_matchesSearch('shortcut') ||
        _matchesSearch('keyboard') ||
        _matchesSearch('binding') ||
        _matchesSearch('key')) {
      sections.add(const ShortcutSettingsSection());
    }

    // Security Section
    if (_matchesSearch('security') ||
        _matchesSearch('lock') ||
        _matchesSearch('pin') ||
        _matchesSearch('biometric')) {
      final lockState = ref.watch(appLockProvider);
      final lockNotifier = ref.read(appLockProvider.notifier);

      sections.add(
        _buildSection(context, 'Security', Icons.security, [
          _buildSwitchSetting(
            'App Lock',
            'Require PIN to access the app',
            lockState.isEnabled,
            (value) {
              if (value && !lockState.hasPin) {
                // Must set PIN first
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PinSetupScreen()),
                );
              } else {
                lockNotifier.setAppLockEnabled(value);
              }
            },
          ),
          if (lockState.isEnabled) ...[
            const Divider(),
            SwitchListTile(
              title: const Text(
                'Use Biometrics',
                style: TextStyle(fontSize: 14),
              ),
              subtitle: const Text(
                'Unlock with Fingerprint or Face ID',
                style: TextStyle(fontSize: 12),
              ),
              value: lockState.isBiometricEnabled,
              onChanged: (val) => lockNotifier.setBiometricEnabled(val),
            ),
            ListTile(
              title: const Text('Change PIN', style: TextStyle(fontSize: 14)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const PinSetupScreen(isChangeMode: true),
                  ),
                );
              },
            ),
          ],
        ]),
      );
    }

    // Backup & Restore Section
    if (_matchesSearch('backup') ||
        _matchesSearch('restore') ||
        _matchesSearch('export') ||
        _matchesSearch('import')) {
      sections.add(
        _buildSection(context, 'Backup & Restore', Icons.save, [
          ListTile(
            title: const Text('Export Backup'),
            subtitle: const Text('Save all settings and sessions to a file'),
            leading: const Icon(Icons.upload_file),
            onTap: () async {
              try {
                final success = await ref
                    .read(backupServiceProvider)
                    .exportBackup();
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Backup exported successfully'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Export failed: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
          ListTile(
            title: const Text('Import Backup'),
            subtitle: const Text('Restore settings and sessions from a file'),
            leading: const Icon(Icons.file_download),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Restore Backup'),
                  content: const Text(
                    'This will overwrite existing settings and sessions. Are you sure?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Restore'),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                if (!context.mounted) return;

                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) =>
                      const Center(child: CircularProgressIndicator()),
                );

                try {
                  await ref.read(backupServiceProvider).importBackup();

                  if (context.mounted) {
                    // Hide loading indicator
                    Navigator.of(context).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Backup restored successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    // Hide loading indicator
                    Navigator.of(context).pop();

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Restore failed: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
          ),
        ]),
      );
    }

    if (sections.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No settings found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        return ListView(
          padding: EdgeInsets.all(isNarrow ? 8 : 16),
          children: sections,
        );
      },
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    if (children.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(children: children),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSliderSetting(
    String title,
    String subtitle,
    double value,
    double min,
    double max,
    int divisions,
    void Function(double) onChanged,
  ) {
    return ListTile(
      title: Text(title, style: const TextStyle(fontSize: 14)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle, style: const TextStyle(fontSize: 12)),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: subtitle,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownSetting<T>(
    String title,
    T value,
    List<(T, String)> items,
    void Function(T) onChanged, {
    String? subtitle,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;

        if (isNarrow) {
          // Vertical layout for narrow screens
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: DropdownButton<T>(
                    value: value,
                    isExpanded: true,
                    onChanged: (newValue) {
                      if (newValue != null) onChanged(newValue);
                    },
                    items: items.map((item) {
                      return DropdownMenuItem(
                        value: item.$1,
                        child: Text(
                          item.$2,
                          style: const TextStyle(fontSize: 14),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        }

        // Horizontal layout for wider screens
        return ListTile(
          title: Text(title, style: const TextStyle(fontSize: 14)),
          subtitle: subtitle != null
              ? Text(subtitle, style: const TextStyle(fontSize: 12))
              : null,
          trailing: DropdownButton<T>(
            value: value,
            onChanged: (newValue) {
              if (newValue != null) onChanged(newValue);
            },
            items: items.map((item) {
              return DropdownMenuItem(
                value: item.$1,
                child: Text(item.$2, style: const TextStyle(fontSize: 14)),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildTextFieldSetting(
    String title,
    String value,
    void Function(String) onChanged, {
    bool obscureText = false,
    String? hintText,
  }) {
    // Note: Recreating controller on every build is not ideal for typing,
    // but acceptable for settings where updates are infrequent/pasted.
    // For a better experience, we would need a stateful widget.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: TextEditingController(text: value)
              ..selection = TextSelection.collapsed(offset: value.length),
            obscureText: obscureText,
            decoration: InputDecoration(
              hintText: hintText,
              isDense: true,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.all(12),
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchSetting(
    String title,
    String subtitle,
    bool value,
    void Function(bool) onChanged,
  ) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontSize: 14)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      value: value,
      onChanged: onChanged,
    );
  }

  Widget _buildColorSchemeSetting(SettingsState settings, dynamic notifier) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        return ListTile(
          title: const Text('Color Scheme', style: TextStyle(fontSize: 14)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                settings.colorScheme.displayName,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: isNarrow ? 4 : 8,
                runSpacing: isNarrow ? 4 : 8,
                children: TerminalColorScheme.values.map((scheme) {
                  final isSelected = settings.colorScheme == scheme;
                  return ChoiceChip(
                    label: Text(
                      scheme.displayName,
                      style: TextStyle(fontSize: isNarrow ? 12 : 14),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) notifier.setColorScheme(scheme);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}
