import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/session_repository.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/database/database.dart';
import 'session_editor_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../terminal/presentation/tab_manager_provider.dart';
import '../../terminal/presentation/widgets/terminal_view_widget.dart';
import '../../terminal/presentation/widgets/resizable_split_view.dart';
import '../../terminal/presentation/widgets/debounced_layout_builder.dart';
import '../../settings/domain/settings_state.dart';
import '../../settings/presentation/settings_provider.dart';
import '../../settings/presentation/shortcuts_provider.dart';
import '../../settings/domain/shortcut_intents.dart';
import '../../settings/domain/shortcut_action.dart';
import '../../terminal/presentation/widgets/sftp_view_widget.dart';
import '../../terminal/data/sftp_service.dart';
import '../../ai_assistant/data/ai_service.dart';

class SessionListScreen extends ConsumerStatefulWidget {
  const SessionListScreen({super.key});

  @override
  ConsumerState<SessionListScreen> createState() => _SessionListScreenState();
}

class _SessionListScreenState extends ConsumerState<SessionListScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final _multiCommandController = TextEditingController();
  bool _showMultiCommandInput = false;

  // AI Assistant State
  final _aiQueryController = TextEditingController();
  final _aiResponseController = TextEditingController();
  bool _showAiAssistant = false;
  bool _isAiLoading = false;
  String? _aiError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    // Listen to tab changes to rebuild UI (for + button visibility)
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    // Check startup mode
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = ref.read(settingsProvider);
      final platform = Theme.of(context).platform;
      final isMobile =
          platform == TargetPlatform.android || platform == TargetPlatform.iOS;

      // Skip local terminal on mobile platforms
      if (settings.startupMode == StartupMode.localTerminal && !isMobile) {
        _openLocalTerminal();
      }
    });

    // Register global key handler
    HardwareKeyboard.instance.addHandler(_handleGlobalStartKey);
  }

  bool _handleGlobalStartKey(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return false;
    }

    final isCtrl = HardwareKeyboard.instance.isControlPressed;
    final isShift = HardwareKeyboard.instance.isShiftPressed;
    final isTab = event.logicalKey == LogicalKeyboardKey.tab;

    if (isTab && isCtrl) {
      if (event is KeyDownEvent) {
        final totalTabs = _tabController.length;
        if (totalTabs <= 1) return true;

        final currentIndex = _tabController.index;
        int nextIndex;

        if (isShift) {
          // Previous tab (Left)
          nextIndex = (currentIndex - 1 + totalTabs) % totalTabs;
        } else {
          // Next tab (Right)
          nextIndex = (currentIndex + 1) % totalTabs;
        }

        _tabController.animateTo(nextIndex);
      }
      return true; // Handled
    }

    // Check for Broadcast Input shortcut
    final shortcuts = ref.read(shortcutsProvider);
    final broadcastActivators = shortcuts[ShortcutAction.broadcastInput] ?? [];
    for (final activator in broadcastActivators) {
      if (activator.accepts(event, HardwareKeyboard.instance)) {
        setState(() {
          _showMultiCommandInput = !_showMultiCommandInput;
        });
        return true;
      }
    }

    // Check for AI Assistant shortcut
    final aiActivators = shortcuts[ShortcutAction.aiAssistant] ?? [];
    for (final activator in aiActivators) {
      if (activator.accepts(event, HardwareKeyboard.instance)) {
        setState(() {
          _showAiAssistant = !_showAiAssistant;
          if (_showAiAssistant) {
            _showMultiCommandInput = false;
          }
        });
        return true;
      }
    }

    return false;
  }

  Future<void> _openLocalTerminal() async {
    final session = Session(
      id: -1, // Temporary ID
      name: 'Local',
      host: 'local',
      port: 0,
      username: '',
      executeLoginScript: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      safetyLevel: 0,
    );
    await ref.read(tabManagerProvider.notifier).createTab(session);
  }

  Future<void> _sendAiQuery(String query) async {
    final settings = ref.read(settingsProvider);
    if (!settings.enableAiAssistant || settings.geminiApiKey.isEmpty) {
      setState(() {
        _aiError = 'Please enable AI Assistant and set API Key in Settings.';
      });
      return;
    }

    setState(() {
      _isAiLoading = true;
      _aiError = null;
      _aiResponseController.clear();
    });

    try {
      final command = await AiService.generateCommand(
        settings.geminiApiKey,
        settings.geminiModel.modelId,
        query,
      );
      if (mounted) {
        setState(() {
          _aiResponseController.text = command;
          _isAiLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _aiError = e.toString().replaceAll('Exception: ', '');
          _isAiLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleGlobalStartKey);
    _tabController.dispose();
    _multiCommandController.dispose();
    _aiQueryController.dispose();
    _aiResponseController.dispose();
    super.dispose();
  }

  void _updateTabController(int tabCount, {int? initialIndex}) {
    final oldController = _tabController;
    final oldIndex = oldController.index;

    _tabController = TabController(
      length: tabCount,
      vsync: this,
      initialIndex: initialIndex ?? oldIndex.clamp(0, tabCount - 1),
    );

    // Add listener to new controller
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    oldController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabManager = ref.watch(tabManagerProvider);
    final totalTabs =
        1 + tabManager.tabs.length; // Session list + terminal tabs

    // Update tab controller if tab count changed
    // We do this synchronously to ensure TabBar gets a controller with correct length
    if (_tabController.length != totalTabs) {
      final int newIndex = tabManager.tabs.isEmpty
          ? 0
          : tabManager.activeTabIndex + 1;
      _updateTabController(totalTabs, initialIndex: newIndex);
    }

    // If lengths don't match, we can't build the TabBar/TabBarView yet.
    // But since we updated synchronously, they SHOULD match.
    final bool isControllerValid = _tabController.length == totalTabs;

    // Determine modifier key based on platform
    final isMacOS = Theme.of(context).platform == TargetPlatform.macOS;

    return Actions(
      actions: {
        NewTabIntent: CallbackAction<NewTabIntent>(
          onInvoke: (_) {
            _tabController.animateTo(0);
            return null;
          },
        ),
        CloseTabIntent: CallbackAction<CloseTabIntent>(
          onInvoke: (_) {
            // Only close if we're on a terminal tab (not session list)
            if (_tabController.index > 0) {
              final tabIndex = _tabController.index - 1;
              ref.read(tabManagerProvider.notifier).closeTab(tabIndex);
            }
            return null;
          },
        ),
        OpenSettingsIntent: CallbackAction<OpenSettingsIntent>(
          onInvoke: (_) {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
            return null;
          },
        ),
        BroadcastInputIntent: CallbackAction<BroadcastInputIntent>(
          onInvoke: (_) {
            setState(() {
              _showMultiCommandInput = !_showMultiCommandInput;
              if (_showMultiCommandInput) {
                _showAiAssistant = false;
              }
            });
            return null;
          },
        ),
        AiAssistantIntent: CallbackAction<AiAssistantIntent>(
          onInvoke: (_) {
            setState(() {
              _showAiAssistant = !_showAiAssistant;
              if (_showAiAssistant) {
                _showMultiCommandInput = false;
              }
            });
            return null;
          },
        ),
      },
      child: PopScope(
        canPop: !_showAiAssistant && !_showMultiCommandInput,
        onPopInvoked: (didPop) {
          if (didPop) return;
          setState(() {
            _showAiAssistant = false;
            _showMultiCommandInput = false;
          });
        },
        child: Scaffold(
          body: Column(
            children: [
              if (isMacOS) const SizedBox(height: 28),
              // Custom Top Bar
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 600;
                    return GestureDetector(
                      onTap: () {
                        // Unfocus any focused terminal to allow global shortcuts to work
                        FocusScope.of(context).requestFocus(FocusNode());
                      },
                      child: Container(
                        height: 40,
                        color: Theme.of(context).colorScheme.surface,
                        child: Row(
                          children: [
                            Expanded(
                              child: TabBar(
                                controller: _tabController,
                                isScrollable: true,
                                tabAlignment: TabAlignment.start,
                                dividerColor: Colors.transparent,
                                labelPadding: EdgeInsets.symmetric(
                                  horizontal: isNarrow ? 8 : 16,
                                ),
                                tabs: [
                                  Tab(
                                    height: 40,
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.list,
                                          size: isNarrow ? 14 : 16,
                                        ),
                                        SizedBox(width: isNarrow ? 4 : 8),
                                        Text(
                                          'Sessions',
                                          style: TextStyle(
                                            fontSize: isNarrow ? 12 : 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ...tabManager.tabs.map(
                                    (tab) => Tab(
                                      height: 40,
                                      child: SizedBox(
                                        width: isNarrow ? 100 : 120,
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                tab.title,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: isNarrow ? 11 : 12,
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: isNarrow ? 2 : 4),
                                            InkWell(
                                              onTap: () {
                                                ref
                                                    .read(
                                                      tabManagerProvider
                                                          .notifier,
                                                    )
                                                    .closeTab(
                                                      tabManager.tabs.indexOf(
                                                        tab,
                                                      ),
                                                    );
                                              },
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Padding(
                                                padding: EdgeInsets.all(
                                                  isNarrow ? 1.0 : 2.0,
                                                ),
                                                child: Icon(
                                                  Icons.close,
                                                  size: isNarrow ? 12 : 14,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Local Terminal Button (desktop only)
                            if (_tabController.index == 0)
                              Builder(
                                builder: (context) {
                                  final platform = Theme.of(context).platform;
                                  final isMobile =
                                      platform == TargetPlatform.android ||
                                      platform == TargetPlatform.iOS;

                                  // Hide local terminal button on mobile
                                  if (isMobile) {
                                    return const SizedBox.shrink();
                                  }

                                  return IconButton(
                                    icon: Icon(
                                      Icons.terminal,
                                      size: isNarrow ? 18 : 20,
                                    ),
                                    tooltip: 'Open Local Terminal',
                                    onPressed: _openLocalTerminal,
                                    padding: EdgeInsets.all(isNarrow ? 8 : 12),
                                    constraints: const BoxConstraints(),
                                  );
                                },
                              ),
                            // + Button (only show on Sessions tab)
                            if (_tabController.index == 0)
                              IconButton(
                                icon: Icon(Icons.add, size: isNarrow ? 18 : 20),
                                tooltip: 'New Session',
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const SessionEditorScreen(),
                                    ),
                                  );
                                },
                                padding: EdgeInsets.all(isNarrow ? 8 : 12),
                                constraints: const BoxConstraints(),
                              ),
                            // Multi Command Toggle
                            IconButton(
                              icon: Icon(
                                Icons.hub,
                                size: isNarrow ? 18 : 20,
                                color: _showMultiCommandInput
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),
                              tooltip: 'Broadcast Command',
                              onPressed: () {
                                setState(() {
                                  _showMultiCommandInput =
                                      !_showMultiCommandInput;
                                  if (_showMultiCommandInput) {
                                    _showAiAssistant = false;
                                  }
                                });
                              },
                              padding: EdgeInsets.all(isNarrow ? 8 : 12),
                              constraints: const BoxConstraints(),
                            ),
                            // AI Assistant Toggle
                            IconButton(
                              icon: Icon(
                                Icons.auto_awesome,
                                size: isNarrow ? 18 : 20,
                                color: _showAiAssistant
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),
                              tooltip: 'AI Assistant',
                              onPressed: () {
                                setState(() {
                                  _showAiAssistant = !_showAiAssistant;
                                  if (_showAiAssistant) {
                                    _showMultiCommandInput = false;
                                  }
                                });
                              },
                              padding: EdgeInsets.all(isNarrow ? 8 : 12),
                              constraints: const BoxConstraints(),
                            ),
                            // Settings Button
                            IconButton(
                              icon: Icon(
                                Icons.settings,
                                size: isNarrow ? 18 : 20,
                              ),
                              tooltip: 'Settings',
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const SettingsScreen(),
                                  ),
                                );
                              },
                              padding: EdgeInsets.all(isNarrow ? 8 : 12),
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              // Content
              Expanded(
                child: (totalTabs > 1 && isControllerValid)
                    ? TabBarView(
                        controller: _tabController,
                        children: [
                          _SessionListView(),
                          ...tabManager.tabs.map((tab) {
                            return _TerminalTabView(tab: tab);
                          }),
                        ],
                      )
                    : _SessionListView(),
              ),
              // Multi Command Input
              if (_showMultiCommandInput)
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context).dividerColor,
                        width: 1,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.hub, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _multiCommandController,
                          autofocus: true,
                          decoration: const InputDecoration(
                            hintText: 'Broadcast command to all sessions...',
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          onSubmitted: (value) {
                            if (value.isNotEmpty) {
                              ref
                                  .read(tabManagerProvider.notifier)
                                  .sendDataToAllSessions('$value\r');
                              _multiCommandController.clear();
                            }
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () {
                          final value = _multiCommandController.text;
                          if (value.isNotEmpty) {
                            ref
                                .read(tabManagerProvider.notifier)
                                .sendDataToAllSessions('$value\r');
                            _multiCommandController.clear();
                          }
                        },
                        tooltip: 'Send to all',
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            _showMultiCommandInput = false;
                          });
                        },
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                ),
              // AI Assistant Input
              if (_showAiAssistant)
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context).dividerColor,
                        width: 1,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _aiQueryController,
                              autofocus: true,
                              enabled: !_isAiLoading,
                              decoration: InputDecoration(
                                hintText: 'Ask for a Linux command...',
                                border: InputBorder.none,
                                isDense: true,
                                suffixIcon: _aiQueryController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 16),
                                        onPressed: () {
                                          _aiQueryController.clear();
                                          setState(() {});
                                        },
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      )
                                    : null,
                              ),
                              onChanged: (_) => setState(() {}),
                              onSubmitted: (value) async {
                                if (value.isNotEmpty && !_isAiLoading) {
                                  await _sendAiQuery(value);
                                }
                              },
                            ),
                          ),
                          if (_isAiLoading)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            IconButton(
                              icon: const Icon(Icons.send),
                              onPressed: () async {
                                final value = _aiQueryController.text;
                                if (value.isNotEmpty && !_isAiLoading) {
                                  await _sendAiQuery(value);
                                }
                              },
                              tooltip: 'Ask AI',
                            ),
                        ],
                      ),
                      if (_aiError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 16,
                                color: Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _aiError!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_aiResponseController.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(context).dividerColor,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: SelectableText(
                                    _aiResponseController.text,
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy, size: 16),
                                  onPressed: () {
                                    Clipboard.setData(
                                      ClipboardData(
                                        text: _aiResponseController.text,
                                      ),
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Command copied to clipboard',
                                        ),
                                        duration: Duration(seconds: 1),
                                      ),
                                    );
                                  },
                                  tooltip: 'Copy Command',
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.keyboard_return,
                                    size: 16,
                                  ),
                                  onPressed: () {
                                    _insertCommandToActiveTerminal(
                                      _aiResponseController.text,
                                    );
                                  },
                                  tooltip: 'Apply to Terminal',
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ), // Column
        ), // Scaffold
      ), // PopScope
    ); // Actions
  } // build method

  void _insertCommandToActiveTerminal(String command) {
    if (_tabController.index == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a terminal tab to apply command.'),
        ),
      );
      return;
    }

    final tabIndex = _tabController.index - 1;
    final tabManager = ref.read(tabManagerProvider);

    if (tabIndex >= tabManager.tabs.length) return;

    final activeTab = tabManager.tabs[tabIndex];
    final activePane = activeTab.panes.firstWhere(
      (p) => p.id == activeTab.activePaneId,
      orElse: () => activeTab.panes.first,
    );

    if (activePane.terminal != null) {
      if (activePane.type == PaneType.sftp) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cannot send command to SFTP view.')),
        );
        return;
      }

      try {
        activePane.terminal!.onOutput?.call(command);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Command inserted into terminal'),
            duration: Duration(milliseconds: 1000),
          ),
        );
      } catch (e) {
        // Ignore
      }
    }
  }
} // _SessionListScreenState

class _SessionListView extends ConsumerStatefulWidget {
  @override
  ConsumerState<_SessionListView> createState() => _SessionListViewState();
}

class _SessionListViewState extends ConsumerState<_SessionListView> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _scrollController = ScrollController();
  bool _isSelectionMode = false;
  final Set<int> _selectedSessionIds = {};
  String _searchQuery = '';
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Auto-focus search bar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleConnect(Session session) async {
    if (_isSelectionMode) {
      _toggleSelection(session.id);
      return;
    }
    print('Connect to ${session.name}');
    try {
      await ref.read(tabManagerProvider.notifier).createTab(session);
      print('createTab completed');
    } catch (e, s) {
      print('createTab failed: $e\n$s');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleSftpConnect(Session session) async {
    if (_isSelectionMode) {
      _toggleSelection(session.id);
      return;
    }
    print('Connect SFTP to ${session.name}');
    try {
      await ref.read(tabManagerProvider.notifier).createSftpTab(session);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect SFTP: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleSelection(int sessionId) {
    setState(() {
      if (_selectedSessionIds.contains(sessionId)) {
        _selectedSessionIds.remove(sessionId);
        if (_selectedSessionIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedSessionIds.add(sessionId);
        _isSelectionMode = true;
      }
    });
  }

  Future<void> _deleteSelectedSessions() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Sessions'),
        content: Text(
          'Are you sure you want to delete ${_selectedSessionIds.length} session(s)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      for (final id in _selectedSessionIds) {
        await ref.read(sessionRepositoryProvider.notifier).deleteSession(id);
      }
      setState(() {
        _selectedSessionIds.clear();
        _isSelectionMode = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Sessions deleted')));
      }
    }
  }

  Future<void> _duplicateSession(Session session) async {
    final current = ref.read(sessionRepositoryProvider).asData?.value ?? [];
    final existingNames = current.map((s) => s.name).toSet();
    // existingNames already defined above
    String baseName = '${session.name} Copy';
    String newName = baseName;
    int copyIndex = 1;
    while (existingNames.contains(newName)) {
      copyIndex++;
      newName = '$baseName $copyIndex';
    }
    final newSession = SessionsCompanion(
      name: drift.Value(newName),
      tag: drift.Value(session.tag),
      host: drift.Value(session.host),
      port: drift.Value(session.port),
      username: drift.Value(session.username),
      password: drift.Value(session.password),
      privateKeyPath: drift.Value(session.privateKeyPath),
      passphrase: drift.Value(session.passphrase),
      loginScript: drift.Value(session.loginScript),
      executeLoginScript: drift.Value(session.executeLoginScript),
    );
    await ref.read(sessionRepositoryProvider.notifier).addSession(newSession);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Session copied as "$newName"')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(sessionRepositoryProvider);

    return sessionsAsync.when(
      data: (sessions) {
        if (sessions.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.terminal, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No sessions found',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Tap + to create your first session',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Filter
        final filteredSessions = sessions.where((s) {
          final name = s.name.toLowerCase();
          final tag = s.tag?.toLowerCase() ?? '';
          final host = s.host.toLowerCase();
          return name.contains(_searchQuery) ||
              tag.contains(_searchQuery) ||
              host.contains(_searchQuery);
        }).toList();

        // Sort: Tagged first (alphabetical), then Untagged (alphabetical by name)
        filteredSessions.sort((a, b) {
          if (a.tag != null && b.tag == null) return -1;
          if (a.tag == null && b.tag != null) return 1;
          if (a.tag != null && b.tag != null) {
            final tagCompare = a.tag!.compareTo(b.tag!);
            if (tagCompare != 0) return tagCompare;
          }
          return a.name.compareTo(b.name);
        });

        // Clamp selected index
        if (_selectedIndex >= filteredSessions.length) {
          _selectedIndex = (filteredSessions.length - 1).clamp(
            0,
            filteredSessions.length,
          );
        }

        return Column(
          children: [
            if (_isSelectionMode)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Row(
                  children: [
                    Text(
                      '${_selectedSessionIds.length} selected',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: _deleteSelectedSessions,
                      tooltip: 'Delete selected',
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _isSelectionMode = false;
                          _selectedSessionIds.clear();
                        });
                      },
                      tooltip: 'Cancel selection',
                    ),
                  ],
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 600;
                  return Padding(
                    padding: EdgeInsets.all(isNarrow ? 8.0 : 16.0),
                    child: CallbackShortcuts(
                      bindings: {
                        const SingleActivator(
                          LogicalKeyboardKey.arrowDown,
                        ): () {
                          setState(() {
                            if (_selectedIndex < filteredSessions.length - 1) {
                              _selectedIndex++;
                              _scrollToSelected();
                            }
                          });
                        },
                        const SingleActivator(LogicalKeyboardKey.arrowUp): () {
                          setState(() {
                            if (_selectedIndex > 0) {
                              _selectedIndex--;
                              _scrollToSelected();
                            }
                          });
                        },
                        const SingleActivator(LogicalKeyboardKey.enter): () {
                          if (filteredSessions.isNotEmpty) {
                            _handleConnect(filteredSessions[_selectedIndex]);
                          }
                        },
                      },
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        decoration: InputDecoration(
                          hintText: isNarrow
                              ? 'Search...'
                              : 'Search sessions or tags...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isNarrow ? 12 : 16,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value.toLowerCase();
                            _selectedIndex = 0; // Reset selection on search
                          });
                        },
                        onSubmitted: (_) {
                          if (filteredSessions.isNotEmpty) {
                            _handleConnect(filteredSessions[_selectedIndex]);
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            Expanded(
              child: filteredSessions.isEmpty
                  ? const Center(child: Text('No matching sessions found'))
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 600;
                        return ListView.builder(
                          controller: _scrollController,
                          itemCount: filteredSessions.length,
                          itemBuilder: (context, index) {
                            final session = filteredSessions[index];
                            final isSelected = index == _selectedIndex;
                            final isChecked = _selectedSessionIds.contains(
                              session.id,
                            );

                            return Card(
                              color: isChecked
                                  ? Theme.of(context)
                                        .colorScheme
                                        .secondaryContainer
                                        .withOpacity(0.5)
                                  : (isSelected
                                        ? Theme.of(context)
                                              .colorScheme
                                              .primaryContainer
                                              .withOpacity(0.3)
                                        : null),
                              margin: EdgeInsets.symmetric(
                                horizontal: isNarrow ? 8 : 16,
                                vertical: isNarrow ? 4 : 8,
                              ),
                              child: ListTile(
                                selected: isSelected,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: isNarrow ? 8 : 16,
                                  vertical: isNarrow ? 4 : 8,
                                ),
                                onTap: () {
                                  setState(() {
                                    _selectedIndex = index;
                                  });
                                  _handleConnect(session);
                                },
                                onLongPress: () {
                                  _toggleSelection(session.id);
                                },
                                leading: _isSelectionMode
                                    ? Checkbox(
                                        value: isChecked,
                                        onChanged: (val) =>
                                            _toggleSelection(session.id),
                                      )
                                    : CircleAvatar(
                                        radius: isNarrow ? 18 : 20,
                                        child: Icon(
                                          session.host.toLowerCase() == 'local'
                                              ? Icons.computer
                                              : Icons.cloud,
                                          size: isNarrow ? 18 : 24,
                                        ),
                                      ),
                                title: Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        session.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: isNarrow ? 14 : 16,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (session.tag != null &&
                                        session.tag!.isNotEmpty) ...[
                                      SizedBox(width: isNarrow ? 4 : 8),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isNarrow ? 6 : 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primaryContainer,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          '#${session.tag}',
                                          style: TextStyle(
                                            fontSize: isNarrow ? 10 : 12,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onPrimaryContainer,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                subtitle: Text(
                                  session.host.toLowerCase() == 'local'
                                      ? 'Local Terminal'
                                      : '${session.username}@${session.host}:${session.port}',
                                  style: TextStyle(
                                    fontSize: isNarrow ? 12 : 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: _isSelectionMode
                                    ? null
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              Icons.copy,
                                              size: isNarrow ? 18 : 24,
                                            ),
                                            tooltip: 'Copy Session',
                                            onPressed: () =>
                                                _duplicateSession(session),
                                            padding: EdgeInsets.all(
                                              isNarrow ? 4 : 8,
                                            ),
                                            constraints: const BoxConstraints(),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.edit,
                                              size: isNarrow ? 18 : 24,
                                            ),
                                            onPressed: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      SessionEditorScreen(
                                                        session: session,
                                                      ),
                                                ),
                                              );
                                            },
                                            padding: EdgeInsets.all(
                                              isNarrow ? 4 : 8,
                                            ),
                                            constraints: const BoxConstraints(),
                                          ),
                                          if (session.host.toLowerCase() !=
                                              'local')
                                            IconButton(
                                              icon: Icon(
                                                Icons.folder_open,
                                                size: isNarrow ? 18 : 24,
                                              ),
                                              tooltip: 'SFTP',
                                              onPressed: () =>
                                                  _handleSftpConnect(session),
                                              padding: EdgeInsets.all(
                                                isNarrow ? 4 : 8,
                                              ),
                                              constraints:
                                                  const BoxConstraints(),
                                            ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.play_arrow,
                                              size: isNarrow ? 18 : 24,
                                            ),
                                            onPressed: () =>
                                                _handleConnect(session),
                                            padding: EdgeInsets.all(
                                              isNarrow ? 4 : 8,
                                            ),
                                            constraints: const BoxConstraints(),
                                          ),
                                        ],
                                      ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $err'),
          ],
        ),
      ),
    );
  }

  void _scrollToSelected() {
    if (_scrollController.hasClients) {
      // Simple scrolling logic: ensure the item is visible
      // A more robust implementation would calculate the item position
      // For now, we can just scroll to index * itemExtent if we had fixed extent
      // Since items are variable height (potentially), we might need a better approach
      // But Card + ListTile usually has a consistent height.
      // Let's approximate for now or just rely on the user scrolling if it's far off
      // Actually, let's try to scroll to make it visible.
      // Assuming item height is roughly 80.0 (Card margin 16 + ListTile height)
      const itemHeight = 88.0;
      final targetOffset = _selectedIndex * itemHeight;

      final currentOffset = _scrollController.offset;
      final viewportHeight = _scrollController.position.viewportDimension;

      if (targetOffset < currentOffset) {
        _scrollController.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
        );
      } else if (targetOffset + itemHeight > currentOffset + viewportHeight) {
        _scrollController.animateTo(
          targetOffset + itemHeight - viewportHeight,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
        );
      }
    }
  }
}

class _TerminalTabView extends ConsumerWidget {
  final TerminalTab tab;

  const _TerminalTabView({required this.tab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ResizableSplitView(
      flexValues: tab.panes.map((p) => p.flex).toList(),
      onFlexChanged: (index, newFlex) {
        ref
            .read(tabManagerProvider.notifier)
            .updatePaneFlex(
              ref.read(tabManagerProvider).tabs.indexOf(tab),
              index,
              newFlex,
            );
      },
      children: tab.panes.map((pane) {
        return DragTarget<int>(
          onWillAcceptWithDetails: (details) {
            final sourceIndex = details.data;
            final targetIndex = ref.read(tabManagerProvider).tabs.indexOf(tab);
            // Don't accept if dragging onto itself
            return sourceIndex != targetIndex;
          },
          onAcceptWithDetails: (details) {
            final sourceIndex = details.data;
            final targetIndex = ref.read(tabManagerProvider).tabs.indexOf(tab);

            // Determine if drop is on left or right half
            final renderBox = context.findRenderObject() as RenderBox;
            final localPosition = renderBox.globalToLocal(details.offset);
            final isLeft = localPosition.dx < renderBox.size.width / 2;

            ref
                .read(tabManagerProvider.notifier)
                .mergeTabs(sourceIndex, targetIndex, insertAtFront: isLeft);
          },
          builder: (context, candidateData, rejectedData) {
            return Container(
              decoration: BoxDecoration(
                color: candidateData.isNotEmpty
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                    : null,
              ),
              child: Stack(
                children: [
                  RepaintBoundary(
                    child: DebouncedLayoutBuilder(
                      delay: const Duration(milliseconds: 200),
                      builder: (context, size) {
                        if (pane.type == PaneType.sftp) {
                          return SftpViewWidget(
                            service: pane.service as SftpService,
                          );
                        }
                        return TerminalViewWidget(
                          key: ValueKey(pane.id),
                          terminal: pane.terminal!,
                          focusNode: pane.focusNode,
                          safetyLevel: pane.session.safetyLevel,
                        );
                      },
                    ),
                  ),
                  // Detach button (only show if multiple panes)
                  if (tab.panes.length > 1)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        icon: const Icon(Icons.open_in_new, size: 16),
                        tooltip: 'Detach to new tab',
                        onPressed: () {
                          ref
                              .read(tabManagerProvider.notifier)
                              .detachPane(
                                ref.read(tabManagerProvider).tabs.indexOf(tab),
                                pane.id,
                              );
                        },
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black54,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      }).toList(),
    );
  }
}
