import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:xterm/xterm.dart';
import '../../../core/database/database.dart';
import '../../settings/presentation/settings_provider.dart';
import '../../settings/domain/settings_state.dart';
import '../data/ssh_service.dart';
import '../data/local_terminal_service.dart';
import '../data/sftp_service.dart';
import '../../session_recording/domain/session_recorder.dart';
import '../../session_recording/data/session_recording_repository.dart';

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
  final SessionRecorder? recorder;
  final int? recordingId;

  TerminalPane({
    required this.id,
    required this.session,
    this.terminal,
    this.type = PaneType.terminal,
    required this.service,
    this.flex = 1.0,
    this.recorder,
    this.recordingId,
  }) : focusNode = FocusNode();

  TerminalPane copyWith({
    double? flex,
    SessionRecorder? recorder,
    int? recordingId,
  }) {
    return TerminalPane(
      id: id,
      session: session,
      terminal: terminal,
      type: type,
      service: service,
      flex: flex ?? this.flex,
      recorder: recorder ?? this.recorder,
      recordingId: recordingId ?? this.recordingId,
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
    SessionRecorder? recorder;
    int? recordingId;

    if (settings.autoRecordSessions) {
      try {
        recorder = SessionRecorder(sessionId: session.id);
        await recorder.start();

        // Create initial DB record
        final repo = ref.read(sessionRecordingRepositoryProvider);
        recordingId = await repo.create(
          sessionId: session.id,
          startTime: recorder.startTime ?? DateTime.now(),
          filePath: recorder.filePath ?? '',
        );
      } catch (e) {
        print('TabManagerNotifier: Error starting auto-recording: $e');
        // Continue connection even if recording fails
      }
    }

    try {
      print('TabManagerNotifier: Resolving session chain...');
      List<Session> chain = [];
      try {
        chain = await _resolveSessionChain(session);
        print(
          'TabManagerNotifier: Chain resolved: ${chain.map((s) => s.host).join(' -> ')}',
        );
      } catch (e) {
        print('TabManagerNotifier: Error resolving chain: $e');
        terminal.write('Error resolving proxy chain: $e\r\n');
        return;
      }

      if (session.host.toLowerCase() == 'local') {
        // Local terminal
        service = LocalTerminalService();
        await service.start(terminal);
      } else {
        // SSH terminal
        service = SSHService();
        print('TabManagerNotifier: Connecting SSH...');
        await service.connect(
          hops: chain,
          terminal: terminal,
          // loginScript: session.loginScript, // Handled internally by service using session data
          // executeLoginScript: session.executeLoginScript, // Handled internally
          encoding: settings.terminalEncoding.charsetName,
          recorder: recorder,
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
        recorder: recorder,
        recordingId: recordingId,
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
  Future<void> closeTab(int index) async {
    if (index < 0 || index >= state.tabs.length) return;

    final tab = state.tabs[index];

    // Stop and save recordings for all panes
    for (final pane in tab.panes) {
      if (pane.recorder != null && pane.recorder!.isRecording) {
        try {
          final file = await pane.recorder!.stop();
          if (file != null && pane.recordingId != null) {
            final repo = ref.read(sessionRecordingRepositoryProvider);
            final length = await file.length();
            await repo.updateEndTimeAndSize(
              pane.recordingId!,
              DateTime.now(),
              length,
            );
          }
        } catch (e) {
          print('Error stopping recording: $e');
        }
      }
    }

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

  Future<void> toggleRecording(int tabIndex, String paneId) async {
    if (tabIndex < 0 || tabIndex >= state.tabs.length) return;

    final tab = state.tabs[tabIndex];
    final paneIndex = tab.panes.indexWhere((p) => p.id == paneId);
    if (paneIndex == -1) return;

    final pane = tab.panes[paneIndex];
    final isRecording = pane.recorder?.isRecording ?? false;

    TerminalPane newPane;

    if (isRecording) {
      // Stop recording
      try {
        final file = await pane.recorder!.stop();
        if (file != null && pane.recordingId != null) {
          final repo = ref.read(sessionRecordingRepositoryProvider);
          final length = await file.length();
          await repo.updateEndTimeAndSize(
            pane.recordingId!,
            DateTime.now(),
            length,
          );
        }
      } catch (e) {
        print('Error stopping recording: $e');
      }

      // Detach recorder from service
      if (pane.service is SSHService) {
        (pane.service as SSHService).setRecorder(null);
      } else if (pane.service is LocalTerminalService) {
        (pane.service as LocalTerminalService).setRecorder(null);
      }

      newPane = TerminalPane(
        id: pane.id,
        session: pane.session,
        terminal: pane.terminal,
        type: pane.type,
        service: pane.service,
        flex: pane.flex,
        recorder: null,
        recordingId: null,
      );
    } else {
      // Start recording
      try {
        final recorder = SessionRecorder(sessionId: pane.session.id);
        await recorder.start();

        final repo = ref.read(sessionRecordingRepositoryProvider);
        final recordingId = await repo.create(
          sessionId: pane.session.id,
          startTime: recorder.startTime ?? DateTime.now(),
          filePath: recorder.filePath ?? '',
        );

        // Attach recorder to service
        if (pane.service is SSHService) {
          (pane.service as SSHService).setRecorder(recorder);
        } else if (pane.service is LocalTerminalService) {
          (pane.service as LocalTerminalService).setRecorder(recorder);
        }

        newPane = TerminalPane(
          id: pane.id,
          session: pane.session,
          terminal: pane.terminal,
          type: pane.type,
          service: pane.service,
          flex: pane.flex,
          recorder: recorder,
          recordingId: recordingId,
        );
      } catch (e) {
        print('Error starting recording: $e');
        return;
      }
    }

    // Update state
    final newPanes = List<TerminalPane>.from(tab.panes);
    newPanes[paneIndex] = newPane;

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

  Future<void> cleanupTabs() async {
    // Stop recording and clean up all tabs
    for (final tab in state.tabs) {
      for (final pane in tab.panes) {
        if (pane.recorder != null && pane.recorder!.isRecording) {
          try {
            final file = await pane.recorder!.stop();
            if (file != null && pane.recordingId != null) {
              final repo = ref.read(sessionRecordingRepositoryProvider);
              final length = await file.length();
              await repo.updateEndTimeAndSize(
                pane.recordingId!,
                DateTime.now(),
                length,
              );
            }
          } catch (e) {
            print('Error stopping recording in cleanup: $e');
          }
        }
      }
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

  Future<List<Session>> _resolveSessionChain(Session session) async {
    final db = ref.read(databaseProvider);
    final List<Session> chain = [session];
    final Set<int> seenIds = {session.id};

    int? currentProxyId = session.proxyJumpId;
    int depth = 0;

    while (currentProxyId != null && depth < 10) {
      if (seenIds.contains(currentProxyId)) {
        throw Exception('Circular proxy jump detected');
      }
      seenIds.add(currentProxyId);

      final parent = await (db.select(
        db.sessions,
      )..where((s) => s.id.equals(currentProxyId!))).getSingleOrNull();

      if (parent == null) break;

      chain.insert(0, parent); // Prepend to chain
      currentProxyId = parent.proxyJumpId;
      depth++;
    }
    return chain;
  }
}

final tabManagerProvider =
    NotifierProvider<TabManagerNotifier, TabManagerState>(
      TabManagerNotifier.new,
    );
