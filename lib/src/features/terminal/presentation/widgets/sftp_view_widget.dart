import 'package:anter/src/features/terminal/presentation/widgets/file_viewer_screen.dart';
import 'package:anter/src/features/terminal/data/sftp_service.dart';
import 'package:flutter/material.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/services.dart';

class SftpViewWidget extends StatefulWidget {
  final SftpService service;

  const SftpViewWidget({super.key, required this.service});

  @override
  State<SftpViewWidget> createState() => _SftpViewWidgetState();
}

class _SftpViewWidgetState extends State<SftpViewWidget> {
  List<SftpName> _files = [];
  bool _isLoading = true;
  String _currentPath = '';
  String? _errorMessage;
  Offset _tapPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final files = await widget.service.listDirectory();
      setState(() {
        _files = files;
        _currentPath = widget.service.currentPath ?? '';
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _navigateTo(String path) async {
    try {
      await widget.service.changeDirectory(path);
      await _loadFiles();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleUpload() async {
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: true);
      if (result != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Uploading...')));

        for (final file in result.files) {
          if (file.path != null) {
            final fileName = p.basename(file.path!);
            // Handle simple concatenation for now, assuming unix-like remote
            final remotePath = _currentPath.endsWith('/')
                ? '$_currentPath$fileName'
                : '$_currentPath/$fileName';
            await widget.service.uploadFile(file.path!, remotePath);
          }
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Upload complete')));
        _loadFiles();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleDownload(SftpName file) async {
    try {
      String? savePath;
      savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save ${file.filename}',
        fileName: file.filename,
      );

      if (savePath == null) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Downloading...')));

      // Handle simple concatenation for now
      final remotePath = _currentPath.endsWith('/')
          ? '$_currentPath${file.filename}'
          : '$_currentPath/${file.filename}';
      await widget.service.downloadFile(remotePath, savePath);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Download complete')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleShare(SftpName file) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final localPath = p.join(tempDir.path, file.filename);
      final remotePath = _currentPath.endsWith('/')
          ? '$_currentPath${file.filename}'
          : '$_currentPath/${file.filename}';

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preparing file for share...')),
      );

      await widget.service.downloadFile(remotePath, localPath);

      // Use Share.shareXFiles (share_plus)
      await Share.shareXFiles([XFile(localPath)]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Share failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleView(SftpName file) async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Opening file...')));
      }

      final remotePath = _currentPath.endsWith('/')
          ? '$_currentPath${file.filename}'
          : '$_currentPath/${file.filename}';

      final content = await widget.service.readFile(remotePath);

      if (mounted) {
        // Clear snackbar
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                FileViewerScreen(filePath: file.filename, content: content),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to read file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleRename(SftpName file) async {
    final controller = TextEditingController(text: file.filename);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'New Name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != file.filename) {
      try {
        final oldPath = _currentPath.endsWith('/')
            ? '$_currentPath${file.filename}'
            : '$_currentPath/${file.filename}';
        final newPath = _currentPath.endsWith('/')
            ? '$_currentPath$newName'
            : '$_currentPath/$newName';

        await widget.service.rename(oldPath, newPath);
        _loadFiles();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Renamed successfully')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Rename failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleDuplicate(SftpName file) async {
    try {
      final oldPath = _currentPath.endsWith('/')
          ? '$_currentPath${file.filename}'
          : '$_currentPath/${file.filename}';

      // Determine new name
      String baseName = file.filename;
      String extension = '';
      if (!file.attr.isDirectory && baseName.contains('.')) {
        extension = p.extension(baseName);
        baseName = p.basenameWithoutExtension(baseName);
      }

      String newName = '${baseName}_copy$extension';
      String newPath = _currentPath.endsWith('/')
          ? '$_currentPath$newName'
          : '$_currentPath/$newName';

      // Check for existence and increment if needed
      int counter = 1;
      while (await widget.service.exists(newPath)) {
        newName = '${baseName}_copy_$counter$extension';
        newPath = _currentPath.endsWith('/')
            ? '$_currentPath$newName'
            : '$_currentPath/$newName';
        counter++;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Duplicating...')));
      await widget.service.duplicate(oldPath, newPath);
      _loadFiles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Duplicated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Duplicate failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showContextMenu(TapDownDetails details, SftpName file) {
    HapticFeedback.selectionClick();
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        details.globalPosition.dx,
        details.globalPosition.dy,
        details.globalPosition.dx,
        details.globalPosition.dy,
      ),
      items: [
        if (file.attr.isDirectory) ...[
          PopupMenuItem(
            child: const ListTile(
              title: Text('Open'),
              leading: Icon(Icons.folder_open),
            ),
            onTap: () => _navigateTo(file.filename),
          ),
        ],
        // Actions available for both files and directories
        PopupMenuItem(
          child: const ListTile(
            title: Text('Rename'),
            leading: Icon(Icons.edit),
          ),
          onTap: () => _handleRename(file),
        ),
        PopupMenuItem(
          child: const ListTile(
            title: Text('Duplicate'),
            leading: Icon(Icons.file_copy),
          ),
          onTap: () => _handleDuplicate(file),
        ),
        if (!file.attr.isDirectory) ...[
          PopupMenuItem(
            child: const ListTile(
              title: Text('View'),
              leading: Icon(Icons.visibility),
            ),
            onTap: () => _handleView(file),
          ),
          PopupMenuItem(
            child: const ListTile(
              title: Text('Download'),
              leading: Icon(Icons.download),
            ),
            onTap: () => _handleDownload(file),
          ),
          PopupMenuItem(
            child: const ListTile(
              title: Text('Share'),
              leading: Icon(Icons.share),
            ),
            onTap: () => _handleShare(file),
          ),
        ],
        PopupMenuItem(
          child: const ListTile(
            title: Text('Delete'),
            leading: Icon(Icons.delete, color: Colors.red),
          ),
          onTap: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Confirm Delete'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              try {
                final fullPath = _currentPath.endsWith('/')
                    ? '$_currentPath${file.filename}'
                    : '$_currentPath/${file.filename}';
                await widget.service.delete(
                  fullPath,
                  isDirectory: file.attr.isDirectory,
                );
                _loadFiles();
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
                }
              }
            }
          },
        ),
      ],
    );
  }

  String _formatSize(int? size) {
    if (size == null) return '-';
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024)
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatPermission(Object? mode) {
    if (mode == null) return '-';
    // If it's the SftpFileMode wrapper, get likely underlying value via toString parsing or property access
    // Since we don't have docs, we'll try to rely on toString() having the number: "SftpFileMode(40755)"
    int? modeVal;

    // Try to access .permissions if available (dynamic check)
    try {
      modeVal = (mode as dynamic).permissions;
    } catch (_) {}

    if (modeVal == null) {
      final str = mode.toString();
      final match = RegExp(r'\((\d+)\)').firstMatch(str);
      if (match != null) {
        modeVal = int.tryParse(match.group(1)!);
      }
    }

    if (modeVal == null) return mode.toString();

    // Convert to octal string to check type
    // But standard permission bits:
    // 0x4000: Directory
    // 0x8000: Regular file
    // 0xA000: Symlink
    // Permissions: last 9 bits.

    final StringBuffer sb = StringBuffer();

    // Type
    if ((modeVal & 0xF000) == 0x4000) {
      sb.write('d');
    } else if ((modeVal & 0xF000) == 0xA000) {
      sb.write('l');
    } else {
      sb.write('-');
    }

    // User
    sb.write((modeVal & 0x100) != 0 ? 'r' : '-');
    sb.write((modeVal & 0x080) != 0 ? 'w' : '-');
    sb.write((modeVal & 0x040) != 0 ? 'x' : '-');

    // Group
    sb.write((modeVal & 0x020) != 0 ? 'r' : '-');
    sb.write((modeVal & 0x010) != 0 ? 'w' : '-');
    sb.write((modeVal & 0x008) != 0 ? 'x' : '-');

    // Other
    sb.write((modeVal & 0x004) != 0 ? 'r' : '-');
    sb.write((modeVal & 0x002) != 0 ? 'w' : '-');
    sb.write((modeVal & 0x001) != 0 ? 'x' : '-');

    return sb.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadFiles, child: const Text('Retry')),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Path bar
        Container(
          padding: const EdgeInsets.all(8.0),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              IconButton(
                onPressed: () => _navigateTo('..'),
                icon: const Icon(Icons.arrow_upward),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.folder_shared, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: SelectableText(
                  _currentPath,
                  style: const TextStyle(fontFamily: 'MesloLGS NF'),
                ),
              ),
              IconButton(
                onPressed: _loadFiles,
                icon: const Icon(Icons.refresh),
              ),
              IconButton(
                onPressed: _handleUpload,
                icon: const Icon(Icons.upload_file),
                tooltip: 'Upload Files',
              ),
            ],
          ),
        ),
        // File List
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      showCheckboxColumn: false,
                      headingRowColor: WidgetStateProperty.all(
                        Theme.of(context).colorScheme.surfaceContainer,
                      ),
                      columns: const [
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Size')),
                        DataColumn(label: Text('Permissions')),
                        DataColumn(label: Text('Modified')),
                      ],
                      rows: _files.map((file) {
                        final isDir = file.attr.isDirectory;
                        // Safe access to attributes. DartSSH2 SftpFileAttrs normally has mtime and mode.
                        // If linter complained, we try to use standard names or workarounds.
                        // Here I use standard names hoping for the best or assuming linter was confused.
                        // If `modifyTime` is missing, I use 0.
                        final mtime = (file.attr.modifyTime ?? 0) * 1000;
                        final mode = file.attr.mode;

                        return DataRow(
                          cells: [
                            DataCell(
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTapDown: (details) =>
                                    _tapPosition = details.globalPosition,
                                onSecondaryTapDown: (details) =>
                                    _showContextMenu(details, file),
                                child: InkWell(
                                  onTap: () {
                                    // Provide visual feedback
                                  },
                                  onDoubleTap: isDir
                                      ? () => _navigateTo(file.filename)
                                      : null,
                                  onLongPress: () => _showContextMenu(
                                    TapDownDetails(
                                      globalPosition: _tapPosition,
                                    ),
                                    file,
                                  ),
                                  child: Container(
                                    constraints: const BoxConstraints(
                                      minHeight: 48,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4.0,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isDir
                                              ? Icons.folder
                                              : Icons.insert_drive_file,
                                          color: isDir
                                              ? Colors.amber
                                              : Theme.of(
                                                  context,
                                                ).iconTheme.color,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(file.filename),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(isDir ? '' : _formatSize(file.attr.size)),
                            ),
                            DataCell(Text(_formatPermission(mode))),
                            DataCell(
                              Text(
                                DateFormat('yyyy-MM-dd HH:mm').format(
                                  DateTime.fromMillisecondsSinceEpoch(mtime),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
