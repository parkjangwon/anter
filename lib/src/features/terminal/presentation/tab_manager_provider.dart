import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xterm/xterm.dart';
import '../../../core/database/database.dart';
import '../../settings/presentation/settings_provider.dart';
import '../../settings/domain/settings_state.dart';
import '../data/ssh_service.dart';
import '../data/local_terminal_service.dart';
import '../data/sftp_service.dart';

enum PaneType { terminal, sftp }

/// Represents a single terminal pane within a tab
class TerminalPane {
  final String id;
  final Session session;
  final Terminal? terminal;
  final PaneType type;
  final dynamic service; // SSHService, LocalTerminalService, or SftpService
  final FocusNode focusNode;
  final double flex;

  TerminalPane({
    required this.id,
    required this.session,
    this.terminal,
    this.type = PaneType.terminal,
    required this.service,
    this.flex = 1.0,
  }) : focusNode = FocusNode();

  TerminalPane copyWith({double? flex}) {
    return TerminalPane(
      id: id,
      session: session,
      terminal: terminal,
      type: type,
      service: service,
      flex: flex ?? this.flex,
    );
  }

  void dispose() {
    service.dispose();
    focusNode.dispose();
  }
}

/// Represents a single terminal tab which can contain multiple panes
class TerminalTab {
  final String id;
  final List<TerminalPane> panes;
  String activePaneId;
  String title;

  TerminalTab({
    required this.id,
    required this.panes,
    required this.activePaneId,
    String? title,
  }) : title = title ?? panes.first.session.name;

  void dispose() {
    for (final pane in panes) {
      pane.dispose();
    }
  }
}

/// State for managing terminal tabs
class TabManagerState {
  final List<TerminalTab> tabs;
  final int activeTabIndex;

  const TabManagerState({this.tabs = const [], this.activeTabIndex = 0});

  TabManagerState copyWith({List<TerminalTab>? tabs, int? activeTabIndex}) {
    return TabManagerState(
      tabs: tabs ?? this.tabs,
      activeTabIndex: activeTabIndex ?? this.activeTabIndex,
    );
  }

  TerminalTab? get activeTab =>
      tabs.isEmpty ? null : tabs[activeTabIndex.clamp(0, tabs.length - 1)];
}

/// Notifier for managing terminal tabs
class TabManagerNotifier extends Notifier<TabManagerState> {
  @override
  TabManagerState build() {
    return const TabManagerState();
  }

  /// Create a new terminal tab for a session
  Future<void> createTab(Session session) async {
    print('TabManagerNotifier: createTab called for ${session.host}');
    final settings = ref.read(settingsProvider);
    final terminal = Terminal(maxLines: settings.scrollBufferSize);
    dynamic service;

    try {
      if (session.host.toLowerCase() == 'local') {
        // Local terminal
        service = LocalTerminalService();
        await service.start(terminal);
      } else {
        // SSH terminal
        service = SSHService();
        print('TabManagerNotifier: Connecting SSH...');
        await service.connect(
          host: session.host,
          port: session.port,
          username: session.username,
          password: session.password,
          privateKeyPath: session.privateKeyPath,
          passphrase: session.passphrase,
          terminal: terminal,
          loginScript: session.loginScript,
          executeLoginScript: session.executeLoginScript,
          encoding: settings.terminalEncoding.charsetName,
        );
        print('TabManagerNotifier: SSH connect returned');
      }

      final paneId = DateTime.now().millisecondsSinceEpoch.toString();
      final pane = TerminalPane(
        id: paneId,
        session: session,
        terminal: terminal,
        service: service,
        type: PaneType.terminal,
      );

      final tab = TerminalTab(
        id: paneId, // Use pane ID as tab ID initially
        panes: [pane],
        activePaneId: paneId,
        title: session.name,
      );

      print('TabManagerNotifier: Adding tab to state');
      state = state.copyWith(
        tabs: [...state.tabs, tab],
        activeTabIndex: state.tabs.length, // Switch to new tab
      );
      print('TabManagerNotifier: Tab added. Total tabs: ${state.tabs.length}');
    } catch (e) {
      print('TabManagerNotifier: Error creating tab: $e');
      // Terminal doesn't need explicit disposal
      rethrow;
    }
  }

  /// Create a new SFTP tab for a session
  Future<void> createSftpTab(Session session) async {
    print('TabManagerNotifier: createSftpTab called for ${session.host}');
    final service = SftpService();

    try {
      print('TabManagerNotifier: Connecting SFTP...');
      await service.connect(
        host: session.host,
        port: session.port,
        username: session.username,
        password: session.password,
        privateKeyPath: session.privateKeyPath,
        passphrase: session.passphrase,
      );
      print('TabManagerNotifier: SFTP connected');

      final paneId = DateTime.now().millisecondsSinceEpoch.toString();
      final pane = TerminalPane(
        id: paneId,
        session: session,
        terminal: null,
        service: service,
        type: PaneType.sftp,
      );

      final tab = TerminalTab(
        id: paneId,
        panes: [pane],
        activePaneId: paneId,
        title: '${session.name} (SFTP)',
      );

      state = state.copyWith(
        tabs: [...state.tabs, tab],
        activeTabIndex: state.tabs.length,
      );
    } catch (e) {
      print('TabManagerNotifier: Error creating SFTP tab: $e');
      rethrow;
    }
  }

  /// Switch to a specific tab
  void switchTab(int index) {
    if (index >= 0 && index < state.tabs.length) {
      state = state.copyWith(activeTabIndex: index);
    }
  }

  /// Close a tab
  void closeTab(int index) {
    if (index < 0 || index >= state.tabs.length) return;

    final tab = state.tabs[index];
    tab.dispose();

    final newTabs = List<TerminalTab>.from(state.tabs)..removeAt(index);
    int newActiveIndex = state.activeTabIndex;

    if (newTabs.isEmpty) {
      newActiveIndex = 0;
    } else if (index <= state.activeTabIndex) {
      newActiveIndex = (state.activeTabIndex - 1).clamp(0, newTabs.length - 1);
    }

    state = state.copyWith(tabs: newTabs, activeTabIndex: newActiveIndex);
  }

  /// Merge source tab into target tab
  void mergeTabs(
    int sourceIndex,
    int targetIndex, {
    bool insertAtFront = false,
  }) {
    if (sourceIndex == targetIndex) return;
    if (sourceIndex < 0 || sourceIndex >= state.tabs.length) return;
    if (targetIndex < 0 || targetIndex >= state.tabs.length) return;

    final sourceTab = state.tabs[sourceIndex];
    final targetTab = state.tabs[targetIndex];

    // Check limit (max 4 panes)
    if (targetTab.panes.length + sourceTab.panes.length > 4) {
      // TODO: Show error or handle gracefully
      return;
    }

    // Combine panes
    final newPanes = insertAtFront
        ? [...sourceTab.panes, ...targetTab.panes]
        : [...targetTab.panes, ...sourceTab.panes];

    // Create new merged tab
    final newTargetTab = TerminalTab(
      id: targetTab.id,
      panes: newPanes,
      activePaneId: targetTab.activePaneId,
      title: '${targetTab.title} + ${sourceTab.title}', // Simple title merge
    );

    final newTabs = List<TerminalTab>.from(state.tabs);
    newTabs[targetIndex] = newTargetTab;
    newTabs.removeAt(sourceIndex);

    // Adjust active index
    int newActiveIndex = targetIndex;
    if (sourceIndex < targetIndex) {
      newActiveIndex--;
    }

    state = state.copyWith(tabs: newTabs, activeTabIndex: newActiveIndex);
  }

  /// Detach a pane from a tab into a new tab
  void detachPane(int tabIndex, String paneId) {
    if (tabIndex < 0 || tabIndex >= state.tabs.length) return;

    final tab = state.tabs[tabIndex];
    if (tab.panes.length <= 1) return; // Cannot detach if only 1 pane

    final paneIndex = tab.panes.indexWhere((p) => p.id == paneId);
    if (paneIndex == -1) return;

    final pane = tab.panes[paneIndex];
    final remainingPanes = List<TerminalPane>.from(tab.panes)
      ..removeAt(paneIndex);

    // Update original tab
    final updatedTab = TerminalTab(
      id: tab.id,
      panes: remainingPanes,
      activePaneId: tab.activePaneId == paneId
          ? remainingPanes.first.id
          : tab.activePaneId,
      title: remainingPanes
          .map((p) => p.session.name)
          .join(' + '), // Update title
    );

    // Create new tab for detached pane
    final newTab = TerminalTab(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      panes: [pane.copyWith(flex: 1.0)], // Reset flex for new tab
      activePaneId: pane.id,
      title: pane.session.name,
    );

    final newTabs = List<TerminalTab>.from(state.tabs);
    newTabs[tabIndex] = updatedTab;
    newTabs.add(newTab);

    state = state.copyWith(tabs: newTabs, activeTabIndex: newTabs.length - 1);
  }

  /// Update pane flex values
  void updatePaneFlex(int tabIndex, int paneIndex, double newFlex) {
    if (tabIndex < 0 || tabIndex >= state.tabs.length) return;

    final tab = state.tabs[tabIndex];
    if (paneIndex < 0 || paneIndex >= tab.panes.length) return;

    final newPanes = List<TerminalPane>.from(tab.panes);
    newPanes[paneIndex] = newPanes[paneIndex].copyWith(flex: newFlex);

    final updatedTab = TerminalTab(
      id: tab.id,
      panes: newPanes,
      activePaneId: tab.activePaneId,
      title: tab.title,
    );

    final newTabs = List<TerminalTab>.from(state.tabs);
    newTabs[tabIndex] = updatedTab;

    state = state.copyWith(tabs: newTabs);
  }

  /// Set active pane in a tab
  void setActivePane(int tabIndex, String paneId) {
    if (tabIndex < 0 || tabIndex >= state.tabs.length) return;

    final tab = state.tabs[tabIndex];
    if (!tab.panes.any((p) => p.id == paneId)) return;

    final updatedTab = TerminalTab(
      id: tab.id,
      panes: tab.panes,
      activePaneId: paneId,
      title: tab.title,
    );

    final newTabs = List<TerminalTab>.from(state.tabs);
    newTabs[tabIndex] = updatedTab;
    state = state.copyWith(tabs: newTabs);
  }

  /// Reorder tabs
  void reorderTabs(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;

    final newTabs = List<TerminalTab>.from(state.tabs);
    final tab = newTabs.removeAt(oldIndex);
    newTabs.insert(newIndex, tab);

    // Adjust active tab index
    int newActiveIndex = state.activeTabIndex;
    if (oldIndex == state.activeTabIndex) {
      newActiveIndex = newIndex;
    } else if (oldIndex < state.activeTabIndex &&
        newIndex >= state.activeTabIndex) {
      newActiveIndex--;
    } else if (oldIndex > state.activeTabIndex &&
        newIndex <= state.activeTabIndex) {
      newActiveIndex++;
    }

    state = state.copyWith(tabs: newTabs, activeTabIndex: newActiveIndex);
  }

  /// Update tab title
  void updateTabTitle(int index, String title) {
    if (index < 0 || index >= state.tabs.length) return;

    final newTabs = List<TerminalTab>.from(state.tabs);
    newTabs[index].title = title;

    state = state.copyWith(tabs: newTabs);
  }

  void cleanupTabs() {
    // Clean up all tabs
    for (final tab in state.tabs) {
      tab.dispose();
    }
  }

  /// Send data to all active terminal sessions
  void sendDataToAllSessions(String data) {
    for (final tab in state.tabs) {
      for (final pane in tab.panes) {
        if (pane.type == PaneType.terminal && pane.terminal != null) {
          try {
            pane.terminal!.onOutput?.call(data);
          } catch (e) {
            print('Error sending data to session ${pane.session.name}: $e');
          }
        }
      }
    }
  }
}

final tabManagerProvider =
    NotifierProvider<TabManagerNotifier, TabManagerState>(
      TabManagerNotifier.new,
    );
