import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import '../../../core/database/database.dart';
import '../data/session_recording_repository.dart';
import 'recording_player_screen.dart';

class RecordingListScreen extends ConsumerStatefulWidget {
  const RecordingListScreen({super.key});

  @override
  ConsumerState<RecordingListScreen> createState() =>
      _RecordingListScreenState();
}

class _RecordingListScreenState extends ConsumerState<RecordingListScreen> {
  final Set<int> _selectedIds = {};

  bool get _isSelectionMode => _selectedIds.isNotEmpty;

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _selectedIds.clear();
    });
  }

  Future<void> _deleteSelected() async {
    final count = _selectedIds.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recordings'),
        content: Text('Are you sure you want to delete $count recording(s)?'),
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

    if (confirm == true) {
      final repo = ref.read(sessionRecordingRepositoryProvider);
      // We need to fetch the recordings to get file paths, or just delete by ID if repo handles it.
      // But we also need to delete files.
      // So let's get all recordings first (cached or fetch).
      // Optimally we should just look up from the list we are displaying, but accessing that from here is tricky without passing data.
      // Let's rely on the current provider data if possible, or fetch.
      final allRecordings = await repo.getAll();
      final toDelete = allRecordings
          .where((r) => _selectedIds.contains(r.id))
          .toList();

      for (final r in toDelete) {
        await repo.deleteRecording(r.id);
        final file = File(r.filePath);
        if (await file.exists()) {
          try {
            await file.delete();
          } catch (e) {
            print('Failed to delete file: $e');
          }
        }
      }

      _exitSelectionMode();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMacOS = Theme.of(context).platform == TargetPlatform.macOS;

    return Scaffold(
      body: Column(
        children: [
          if (isMacOS) const SizedBox(height: 28),
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
                      if (_isSelectionMode) ...[
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: _exitSelectionMode,
                          tooltip: 'Cancel Selection',
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_selectedIds.length} Selected',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.redAccent,
                          ),
                          onPressed: _deleteSelected,
                          tooltip: 'Delete Selected',
                        ),
                      ] else ...[
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.of(context).pop(),
                          padding: EdgeInsets.all(isNarrow ? 8 : 12),
                          constraints: const BoxConstraints(),
                        ),
                        SizedBox(width: isNarrow ? 8 : 16),
                        const Text(
                          'Session Recordings',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.file_upload),
                          tooltip: 'Import Recording',
                          onPressed: _importRecording,
                          padding: EdgeInsets.all(isNarrow ? 8 : 12),
                          constraints: const BoxConstraints(),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () {
                            // Manual refresh is tricky with StreamProvider, but since it is a stream,
                            // we generally don't need manual refresh.
                            // However, if we want to support it, we technically re-read the provider?
                            // For StreamProvider, usually we don't need this button.
                            // But user asked for it previously. Since we switched to Stream loop,
                            // it's auto-updating. We can keep it or remove it.
                            // Let's keep it but maybe it re-evaluates the query?
                            ref.invalidate(sessionRecordingsListProvider);
                          },
                          tooltip: 'Refresh',
                          padding: EdgeInsets.all(isNarrow ? 8 : 12),
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: ref
                .watch(sessionRecordingsListProvider)
                .when(
                  data: (recordings) {
                    if (recordings.isEmpty) {
                      return const Center(child: Text('No recordings found'));
                    }
                    return ListView.builder(
                      itemCount: recordings.length,
                      itemBuilder: (context, index) {
                        final recording = recordings[index];
                        final isSelected = _selectedIds.contains(recording.id);

                        return ListTile(
                          leading: _isSelectionMode
                              ? Checkbox(
                                  value: isSelected,
                                  onChanged: (val) =>
                                      _toggleSelection(recording.id),
                                )
                              : const Icon(Icons.movie),
                          title: Text(
                            'Session #${recording.sessionId} - ${DateFormat('yyyy-MM-dd HH:mm:ss').format(recording.startTime)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${recording.filePath.split('/').last}\n'
                            'Size: ${(recording.fileSize / 1024).toStringAsFixed(1)} KB',
                          ),
                          isThreeLine: true,
                          selected: isSelected,
                          onTap: () {
                            if (_isSelectionMode) {
                              _toggleSelection(recording.id);
                            } else {
                              _playRecording(recording);
                            }
                          },
                          onLongPress: () => _toggleSelection(recording.id),
                          trailing: !_isSelectionMode
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Platform.isWindows ||
                                                Platform.isLinux ||
                                                Platform.isMacOS
                                            ? Icons.download
                                            : Icons.share,
                                      ),
                                      tooltip:
                                          Platform.isWindows ||
                                              Platform.isLinux ||
                                              Platform.isMacOS
                                          ? 'Save Recording'
                                          : 'Share Recording',
                                      onPressed: () =>
                                          _exportRecording(recording),
                                    ),
                                  ],
                                )
                              : null,
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(child: Text('Error: $error')),
                ),
          ),
        ],
      ),
    );
  }

  void _playRecording(SessionRecording recording) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RecordingPlayerScreen(recording: recording),
      ),
    );
  }

  Future<void> _exportRecording(SessionRecording recording) async {
    final file = File(recording.filePath);
    if (!await file.exists()) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('File not found')));
      }
      return;
    }

    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // Desktop: Save As Dialog
      var fileName = file.uri.pathSegments.last;
      // Strip extension to prevent double extension (e.g. .rec.rec)
      if (fileName.toLowerCase().endsWith('.rec')) {
        fileName = fileName.substring(0, fileName.length - 4);
      }

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Recording As',
        fileName: fileName,
        allowedExtensions: ['rec', 'txt', 'json'],
        type: FileType.custom,
      );

      if (outputFile != null) {
        try {
          await file.copy(outputFile);
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Saved to $outputFile')));
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
          }
        }
      }
    } else {
      // Mobile: Share
      await Share.shareXFiles([
        XFile(file.path),
      ], text: 'Session Recording export');
    }
  }

  Future<void> _importRecording() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null && result.files.single.path != null) {
        final srcFile = File(result.files.single.path!);
        final appDir = await getApplicationDocumentsDirectory();
        final recordingsDir = Directory('${appDir.path}/recordings');
        if (!await recordingsDir.exists()) {
          await recordingsDir.create(recursive: true);
        }

        final filename =
            'imported_${DateTime.now().millisecondsSinceEpoch}.rec';
        final destPath = '${recordingsDir.path}/$filename';
        await srcFile.copy(destPath);

        // Parse metadata if possible
        int sessionId = -1; // Imported
        DateTime startTime = DateTime.now();

        try {
          final firstLine = await srcFile
              .openRead()
              .transform(utf8.decoder)
              .transform(const LineSplitter())
              .first;
          final json = jsonDecode(firstLine);
          if (json is Map) {
            if (json['sessionId'] is int) sessionId = json['sessionId'];
            if (json['timestamp'] is String)
              startTime = DateTime.tryParse(json['timestamp']) ?? startTime;
          }
        } catch (e) {
          // Ignore parsing error, treat as raw import
        }

        final repo = ref.read(sessionRecordingRepositoryProvider);
        final id = await repo.create(
          sessionId: sessionId,
          startTime: startTime,
          filePath: destPath,
        );

        // Update size/end time
        final len = await srcFile.length();
        await repo.updateEndTimeAndSize(id, DateTime.now(), len);

        // setState(() {}); // Not needed with StreamProvider usually
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recording imported successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
      }
    }
  }
} // End of class
