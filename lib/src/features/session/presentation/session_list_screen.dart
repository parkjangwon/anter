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

class SessionListScreen extends ConsumerStatefulWidget {
  const SessionListScreen({super.key});

  @override
  ConsumerState<SessionListScreen> createState() => _SessionListScreenState();
}

class _SessionListScreenState extends ConsumerState<SessionListScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

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
      if (settings.startupMode == StartupMode.localTerminal) {
        _openLocalTerminal();
      }
    });
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
    );
    await ref.read(tabManagerProvider.notifier).createTab(session);
  }

  @override
  void dispose() {
    _tabController.dispose();
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

    return FocusScope(
      child: Focus(
        autofocus: true,
        child: Shortcuts(
          shortcuts: {
            // Tab navigation - always use Ctrl+Tab (even on macOS)
            const SingleActivator(LogicalKeyboardKey.tab, control: true):
                const NextTabIntent(),
            const SingleActivator(
              LogicalKeyboardKey.tab,
              control: true,
              shift: true,
            ): const PreviousTabIntent(),
            // New tab / Go to sessions
            SingleActivator(
              LogicalKeyboardKey.keyT,
              control: !isMacOS,
              meta: isMacOS,
            ): const GoToSessionsIntent(),
            // Close tab
            SingleActivator(
              LogicalKeyboardKey.keyW,
              control: !isMacOS,
              meta: isMacOS,
            ): const CloseTabIntent(),
            // Settings
            SingleActivator(
              LogicalKeyboardKey.comma,
              control: !isMacOS,
              meta: isMacOS,
            ): const OpenSettingsIntent(),
          },
          child: Actions(
            actions: {
              NextTabIntent: CallbackAction<NextTabIntent>(
                onInvoke: (_) {
                  final currentIndex = _tabController.index;
                  final nextIndex = (currentIndex + 1) % totalTabs;
                  _tabController.animateTo(nextIndex);
                  return null;
                },
              ),
              PreviousTabIntent: CallbackAction<PreviousTabIntent>(
                onInvoke: (_) {
                  final currentIndex = _tabController.index;
                  final prevIndex = (currentIndex - 1 + totalTabs) % totalTabs;
                  _tabController.animateTo(prevIndex);
                  return null;
                },
              ),
              GoToSessionsIntent: CallbackAction<GoToSessionsIntent>(
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
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                  return null;
                },
              ),
            },
            child: Scaffold(
              body: Column(
                children: [
                  if (isMacOS) const SizedBox(height: 28),
                  // Custom Top Bar
                  SafeArea(
                    child: GestureDetector(
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
                                labelPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                tabs: [
                                  const Tab(
                                    height: 40,
                                    child: Row(
                                      children: [
                                        Icon(Icons.list, size: 16),
                                        SizedBox(width: 8),
                                        Text('Sessions'),
                                      ],
                                    ),
                                  ),
                                  ...tabManager.tabs.asMap().entries.map((
                                    entry,
                                  ) {
                                    final index = entry.key;
                                    final tab = entry.value;
                                    final tabContent = SizedBox(
                                      width: 120,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              tab.title,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          InkWell(
                                            onTap: () {
                                              ref
                                                  .read(
                                                    tabManagerProvider.notifier,
                                                  )
                                                  .closeTab(index);
                                            },
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: const Padding(
                                              padding: EdgeInsets.all(2.0),
                                              child: Icon(
                                                Icons.close,
                                                size: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );

                                    return Draggable<int>(
                                      data: index,
                                      feedback: Material(
                                        child: ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            maxWidth: 150,
                                            maxHeight: 40,
                                          ),
                                          child: Tab(
                                            height: 40,
                                            child: tabContent,
                                          ),
                                        ),
                                      ),
                                      child: Tab(height: 40, child: tabContent),
                                    );
                                  }),
                                ],
                              ),
                            ),
                            // Local Terminal Button
                            if (_tabController.index == 0)
                              IconButton(
                                icon: const Icon(Icons.terminal, size: 20),
                                tooltip: 'Open Local Terminal',
                                onPressed: _openLocalTerminal,
                              ),
                            // + Button (only show on Sessions tab)
                            if (_tabController.index == 0)
                              IconButton(
                                icon: const Icon(Icons.add, size: 20),
                                tooltip: 'New Session',
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const SessionEditorScreen(),
                                    ),
                                  );
                                },
                              ),
                            // Settings Button
                            IconButton(
                              icon: const Icon(Icons.settings, size: 20),
                              tooltip: 'Settings',
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const SettingsScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
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
                ],
              ), // Column
            ), // Scaffold
          ), // Actions
        ), // Shortcuts
      ), // Focus
    ); // FocusScope
  } // build method
} // _SessionListScreenState

// Intent classes for keyboard shortcuts
class NextTabIntent extends Intent {
  const NextTabIntent();
}

class PreviousTabIntent extends Intent {
  const PreviousTabIntent();
}

class CloseTabIntent extends Intent {
  const CloseTabIntent();
}

class GoToSessionsIntent extends Intent {
  const GoToSessionsIntent();
}

class OpenSettingsIntent extends Intent {
  const OpenSettingsIntent();
}

class _SessionListView extends ConsumerStatefulWidget {
  @override
  ConsumerState<_SessionListView> createState() => _SessionListViewState();
}

class _SessionListViewState extends ConsumerState<_SessionListView> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _scrollController = ScrollController();
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
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CallbackShortcuts(
                bindings: {
                  const SingleActivator(LogicalKeyboardKey.arrowDown): () {
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
                    hintText: 'Search sessions or tags...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
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
            ),
            Expanded(
              child: filteredSessions.isEmpty
                  ? const Center(child: Text('No matching sessions found'))
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: filteredSessions.length,
                      itemBuilder: (context, index) {
                        final session = filteredSessions[index];
                        final isSelected = index == _selectedIndex;
                        return Card(
                          color: isSelected
                              ? Theme.of(
                                  context,
                                ).colorScheme.primaryContainer.withOpacity(0.3)
                              : null,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            selected: isSelected,
                            onTap: () {
                              setState(() {
                                _selectedIndex = index;
                              });
                              _handleConnect(session);
                            },
                            leading: CircleAvatar(
                              child: Icon(
                                session.host.toLowerCase() == 'local'
                                    ? Icons.computer
                                    : Icons.cloud,
                              ),
                            ),
                            title: Row(
                              children: [
                                Text(
                                  session.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (session.tag != null &&
                                    session.tag!.isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '#${session.tag}',
                                      style: TextStyle(
                                        fontSize: 12,
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
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.copy),
                                  tooltip: 'Copy Session',
                                  onPressed: () => _duplicateSession(session),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => SessionEditorScreen(
                                          session: session,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.play_arrow),
                                  onPressed: () => _handleConnect(session),
                                ),
                              ],
                            ),
                          ),
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
                        return TerminalViewWidget(
                          key: ValueKey(pane.id),
                          terminal: pane.terminal,
                          focusNode: pane.focusNode,
                          onInput: (input) {
                            pane.service.write(input);
                          },
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
