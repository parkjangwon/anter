import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:xterm/xterm.dart';
import '../../../core/database/database.dart';

// Actually TerminalViewWidget wraps TerminalView with search etc.
// I'll use TerminalView directly for simplicity or verify existence.

class RecordingPlayerScreen extends ConsumerStatefulWidget {
  final SessionRecording recording;

  const RecordingPlayerScreen({super.key, required this.recording});

  @override
  ConsumerState<RecordingPlayerScreen> createState() =>
      _RecordingPlayerScreenState();
}

class _Frame {
  final int time;
  final String data;
  _Frame(this.time, this.data);
}

class _RecordingPlayerScreenState extends ConsumerState<RecordingPlayerScreen> {
  late Terminal _terminal;
  final _terminalController = TerminalController();

  List<_Frame> _frames = [];
  bool _isLoading = true;
  String? _error;

  // Playback state
  bool _isPlaying = false;
  int _currentTimeMs = 0;
  int _durationMs = 0;
  double _playbackSpeed = 1.0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _terminal = Terminal();
    _loadRecording();
  }

  Future<void> _loadRecording() async {
    try {
      final file = File(widget.recording.filePath);
      if (!await file.exists()) {
        throw Exception('File not found: ${widget.recording.filePath}');
      }

      final lines = await file.readAsLines();
      final frames = <_Frame>[];
      int maxTime = 0;

      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        try {
          final json = jsonDecode(line);
          if (json is Map) {
            // Header or metadata?
            continue; // Skip header for now
          }
          if (json is List && json.length >= 3) {
            final time = json[0] as int;
            // final type = json[1] as String;
            final data = json[2] as String;

            // Only process output for replay
            // if (type == 'o') {
            // actually we might want input too if we want to see typing?
            // But usually output contains echoes.
            // Let's record everything that is in the file.

            frames.add(_Frame(time, data));
            if (time > maxTime) maxTime = time;
          }
        } catch (e) {
          // Skip malformed lines
        }
      }

      setState(() {
        _frames = frames;
        _durationMs = maxTime;
        _isLoading = false;
      });

      // Auto play
      _play();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _play() {
    if (_isPlaying) return;
    if (_currentTimeMs >= _durationMs) {
      _currentTimeMs = 0;
      _currentFrameIndex = 0;
      _terminal.buffer.clear();
      _terminal.setCursor(0, 0);
    }

    setState(() => _isPlaying = true);
    final tickInterval = 16; // ~60fps
    _timer = Timer.periodic(Duration(milliseconds: tickInterval), (timer) {
      final delta = (tickInterval * _playbackSpeed).round();
      final newTime = _currentTimeMs + delta;

      _renderFramesIncremental(newTime);

      setState(() {
        _currentTimeMs = newTime;
      });

      if (_currentTimeMs >= _durationMs) {
        _pause();
        _currentTimeMs = _durationMs;
      }
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _isPlaying = false);
  }

  void _togglePlay() {
    if (_isPlaying)
      _pause();
    else
      _play();
  }

  int _currentFrameIndex = 0;

  void _renderFramesIncremental(int endTime) {
    while (_currentFrameIndex < _frames.length) {
      final frame = _frames[_currentFrameIndex];
      if (frame.time <= endTime) {
        _terminal.write(frame.data);
        _currentFrameIndex++;
      } else {
        break;
      }
    }
  }

  void _seek(double value) {
    final timeMs = value.toInt();
    _pause();

    // To seek, we must replay from start to target time
    _terminal.buffer.clear();
    _terminal.setCursor(0, 0); // Reset terminal state
    // Reset ANSI state? _terminal.reset() might be better but it clears buffer too.

    _currentFrameIndex = 0;
    _renderFramesIncremental(timeMs);

    setState(() {
      _currentTimeMs = timeMs;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMacOS = Theme.of(context).platform == TargetPlatform.macOS;

    return Scaffold(
      body: Column(
        children: [
          if (isMacOS) const SizedBox(height: 28),
          SafeArea(
            bottom: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor.withOpacity(0.5),
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Session Replay',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Session #${widget.recording.sessionId}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                : Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: TerminalView(
                      _terminal,
                      controller: _terminalController,
                      autofocus: true,
                      readOnly: true,
                      backgroundOpacity: 1, // Ensure solid background
                    ),
                  ),
          ),
          if (!_isLoading && _error == null) _buildControls(),
        ],
      ),
    );
  }

  Widget _buildControls() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Time and Slider
          Row(
            children: [
              Text(
                _formatTime(_currentTimeMs),
                style: const TextStyle(
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 14,
                    ),
                    activeTrackColor: colorScheme.primary,
                    inactiveTrackColor: colorScheme.surfaceContainerHighest,
                    thumbColor: colorScheme.primary,
                  ),
                  child: Slider(
                    value: _currentTimeMs.toDouble().clamp(
                      0,
                      _durationMs.toDouble(),
                    ),
                    min: 0,
                    max: _durationMs.toDouble(),
                    onChanged: _seek,
                  ),
                ),
              ),
              Text(
                _formatTime(_durationMs),
                style: const TextStyle(
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Speed Control
              SizedBox(
                width: 100,
                child: PopupMenuButton<double>(
                  initialValue: _playbackSpeed,
                  tooltip: 'Playback Speed',
                  itemBuilder: (context) => [0.5, 1.0, 2.0, 4.0, 8.0]
                      .map(
                        (speed) => PopupMenuItem(
                          value: speed,
                          child: Text('${speed}x'),
                        ),
                      )
                      .toList(),
                  onSelected: (v) => setState(() => _playbackSpeed = v),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${_playbackSpeed}x',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.speed, size: 16),
                      ],
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // Play/Pause
              IconButton(
                iconSize: 48,
                icon: Icon(
                  _isPlaying
                      ? Icons.pause_circle_filled_rounded
                      : Icons.play_circle_fill_rounded,
                  color: colorScheme.primary,
                ),
                onPressed: _togglePlay,
                padding: EdgeInsets.zero,
              ),

              const Spacer(),

              // Placeholder for balance or extra tools
              const SizedBox(width: 100),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime(int ms) {
    final duration = Duration(milliseconds: ms);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
