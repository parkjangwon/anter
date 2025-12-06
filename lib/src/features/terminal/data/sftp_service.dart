import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:dartssh2/dartssh2.dart';

class SftpService {
  SSHClient? _client;
  SftpClient? _sftp;
  String? _currentPath;

  bool get isConnected => _client != null && _sftp != null;
  String? get currentPath => _currentPath;

  Future<void> connect({
    required String host,
    required int port,
    required String username,
    String? password,
    String? privateKeyPath,
    String? passphrase,
  }) async {
    try {
      final socket = await SSHSocket.connect(host, port);

      _client = SSHClient(
        socket,
        username: username,
        onPasswordRequest: () {
          if (password != null) return password;
          return '';
        },
        identities: privateKeyPath != null
            ? await _loadIdentity(privateKeyPath, passphrase)
            : [],
      );

      await _client!.authenticated;
      _sftp = await _client!.sftp();

      // Initialize path to absolute path using pwd
      try {
        final result = await _client!.run('pwd');
        _currentPath = String.fromCharCodes(result).trim();
      } catch (e) {
        // Fallback if pwd fails, though unexpected on standard SSH
        _currentPath = '.';
      }
    } catch (e) {
      _client?.close();
      rethrow;
    }
  }

  Future<List<SSHKeyPair>> _loadIdentity(
    String privateKeyPath,
    String? passphrase,
  ) async {
    try {
      final file = File(privateKeyPath);
      if (!await file.exists()) {
        return [];
      }
      final keyContent = await file.readAsString();
      return SSHKeyPair.fromPem(keyContent, passphrase);
    } catch (e) {
      return [];
    }
  }

  Future<List<SftpName>> listDirectory([String? path]) async {
    if (_sftp == null) throw Exception('Not connected');
    final targetPath = path ?? _currentPath!;
    final files = await _sftp!.listdir(targetPath);

    // Sort: Directories first, then files. Alphabetical.
    files.sort((a, b) {
      final aIsDir = a.attr.isDirectory;
      final bIsDir = b.attr.isDirectory;
      if (aIsDir && !bIsDir) return -1;
      if (!aIsDir && bIsDir) return 1;
      return a.filename.compareTo(b.filename);
    });

    return files;
  }

  Future<void> changeDirectory(String path) async {
    if (_sftp == null) throw Exception('Not connected');

    // Normalize the path using posix context (standard for SFTP)
    // If path is absolute, normalize it.
    // If relative, join with current path and normalize.
    String newPath;
    if (p.posix.isAbsolute(path)) {
      newPath = p.posix.normalize(path);
    } else {
      newPath = p.posix.normalize(p.posix.join(_currentPath ?? '.', path));
    }

    final stat = await _sftp!.stat(newPath);
    if (!stat.isDirectory) {
      throw Exception('$newPath is not a directory');
    }

    _currentPath = newPath;
  }

  Future<void> downloadFile(String remotePath, String localPath) async {
    if (_sftp == null) throw Exception('Not connected');

    final remoteFile = await _sftp!.open(remotePath);
    final localFile = File(localPath);
    final sink = localFile.openWrite();

    try {
      final stream = remoteFile.read(
        length: (await remoteFile.stat()).size ?? 0,
      );
      // Cast stream from Uint8List to List<int> for file writing
      await sink.addStream(stream.cast<List<int>>());
    } finally {
      await sink.close();
      await remoteFile.close();
    }
  }

  Future<void> uploadFile(String localPath, String remotePath) async {
    if (_sftp == null) throw Exception('Not connected');

    final localFile = File(localPath);
    final remoteFile = await _sftp!.open(
      remotePath,
      mode:
          SftpFileOpenMode.write |
          SftpFileOpenMode.create |
          SftpFileOpenMode.truncate,
    );

    try {
      // Convert List<int> stream to Uint8List stream
      final stream = localFile.openRead().map(
        (chunk) => Uint8List.fromList(chunk),
      );
      await remoteFile.write(stream);
    } finally {
      await remoteFile.close();
    }
  }

  Future<void> delete(String path, {bool isDirectory = false}) async {
    if (_sftp == null) throw Exception('Not connected');
    if (isDirectory) {
      await _sftp!.rmdir(path);
    } else {
      await _sftp!.remove(path);
    }
  }

  Future<void> rename(String oldPath, String newPath) async {
    if (_sftp == null) throw Exception('Not connected');
    await _sftp!.rename(oldPath, newPath);
  }

  Future<bool> exists(String path) async {
    try {
      if (_sftp == null) return false;
      await _sftp!.stat(path);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> duplicate(String sourcePath, String destPath) async {
    if (_sftp == null) throw Exception('Not connected');

    print('SftpService: Duplicating "$sourcePath" to "$destPath"');

    final stat = await _sftp!.stat(sourcePath);

    if (stat.isDirectory) {
      final client = _client;
      if (client == null) throw Exception('Not connected (Client null)');

      // Use cp -r for directories as recursive SFTP copy is complex/slow
      final escSource = sourcePath.replaceAll("'", "'\\''");
      final escDest = destPath.replaceAll("'", "'\\''");

      final cmd = "cp -r '$escSource' '$escDest'";
      print('SftpService: Executing directory copy: $cmd');

      final session = await client.execute(cmd);

      final stderrBuffer = StringBuffer();
      session.stderr.listen((data) {
        final str = String.fromCharCodes(data);
        print('SftpService stderr: $str');
        stderrBuffer.write(str);
      });

      final exitCode = await session.exitCode;

      if ((exitCode != null && exitCode != 0) ||
          (exitCode == null && stderrBuffer.isNotEmpty)) {
        throw Exception(
          stderrBuffer.isNotEmpty
              ? stderrBuffer.toString().trim()
              : 'Directory copy failed with exit code $exitCode',
        );
      }
    } else {
      // Use SFTP read/write for single files to avoid shell permission quirks
      try {
        final sourceFile = await _sftp!.open(
          sourcePath,
          mode: SftpFileOpenMode.read,
        );
        final destFile = await _sftp!.open(
          destPath,
          mode:
              SftpFileOpenMode.write |
              SftpFileOpenMode.create |
              SftpFileOpenMode.truncate,
        );

        try {
          // Pipe read stream to write stream
          await destFile.write(sourceFile.read());
        } finally {
          await sourceFile.close();
          await destFile.close();
        }
      } catch (e) {
        print('SftpService: File copy failed: $e');

        // Enhance error message with directory listing if permission denied
        if (e.toString().contains('Permission denied') ||
            e.toString().contains('code 3')) {
          try {
            final parentDir = p.dirname(destPath);
            final result = await _client!.run('ls -ld "$parentDir"');
            final perms = String.fromCharCodes(result).trim();
            throw Exception(
              'File copy failed: Permission denied. \nDirectory permissions: $perms',
            );
          } catch (_) {
            // Ignore diagnostic failure
          }
        }
        throw Exception('File copy failed: $e');
      }
    }
  }

  void dispose() {
    _client?.close();
  }
}
