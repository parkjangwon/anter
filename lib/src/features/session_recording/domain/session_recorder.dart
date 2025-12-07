import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

class SessionRecorder {
  final int sessionId;
  File? _file;
  IOSink? _sink;
  DateTime? _startTime;
  bool _isRecording = false;

  bool get isRecording => _isRecording;
  String? get filePath => _file?.path;
  DateTime? get startTime => _startTime;

  SessionRecorder({required this.sessionId});

  Future<void> start() async {
    if (_isRecording) return;

    final directory = await getApplicationDocumentsDirectory();
    final recordingsDir = Directory('${directory.path}/recordings');
    if (!await recordingsDir.exists()) {
      await recordingsDir.create(recursive: true);
    }

    _startTime = DateTime.now();
    final timestamp = DateFormat('yyyyMMddHHmmss').format(_startTime!);
    final fileName = 'session_${sessionId}_$timestamp.rec';
    _file = File('${recordingsDir.path}/$fileName');
    _sink = _file!.openWrite();

    // Write header
    _sink!.writeln(
      jsonEncode({
        'version': 1,
        'sessionId': sessionId,
        'startTime': _startTime!.toIso8601String(),
      }),
    );

    _isRecording = true;
  }

  void write(String data, {bool isInput = false}) {
    if (!_isRecording || _sink == null || _startTime == null) return;

    final timestamp = DateTime.now().difference(_startTime!).inMilliseconds;
    // Format: [timestamp, type, data]
    // type: "o" for output, "i" for input
    final record = [timestamp, isInput ? 'i' : 'o', data];
    _sink!.writeln(jsonEncode(record));
  }

  Future<File?> stop() async {
    if (!_isRecording) return null;

    _isRecording = false;
    await _sink?.flush();
    await _sink?.close();

    final file = _file;
    _sink = null;
    _file = null;
    _startTime = null;

    return file;
  }
}
