import 'dart:async';
import 'package:flutter/material.dart';

class DebouncedLayoutBuilder extends StatefulWidget {
  final Widget Function(BuildContext context, Size size) builder;
  final Duration delay;

  const DebouncedLayoutBuilder({
    super.key,
    required this.builder,
    this.delay = const Duration(milliseconds: 200),
  });

  @override
  State<DebouncedLayoutBuilder> createState() => _DebouncedLayoutBuilderState();
}

class _DebouncedLayoutBuilderState extends State<DebouncedLayoutBuilder> {
  Timer? _timer;
  Size? _currentSize;
  Size? _targetSize;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final newSize = constraints.biggest;

        if (_currentSize == null) {
          // First build, initialize immediately
          _currentSize = newSize;
        } else if (newSize != _targetSize) {
          // Size changed, schedule update
          _targetSize = newSize;
          _timer?.cancel();
          _timer = Timer(widget.delay, () {
            if (mounted) {
              setState(() {
                _currentSize = _targetSize;
                _timer = null;
              });
            }
          });
        }

        // Always use the _currentSize for the child
        // If we are resizing, _currentSize will be the OLD size until timer fires.
        // We use OverflowBox to allow the child to be its old size within the new constraints.

        return ClipRect(
          child: OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: 0,
            minHeight: 0,
            maxWidth: double.infinity,
            maxHeight: double.infinity,
            child: SizedBox.fromSize(
              size: _currentSize,
              child: widget.builder(context, _currentSize!),
            ),
          ),
        );
      },
    );
  }
}
