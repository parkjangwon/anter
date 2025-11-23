import 'package:flutter/material.dart';

class ResizableSplitView extends StatefulWidget {
  final List<Widget> children;
  final List<double> flexValues;
  final Function(int index, double newFlex) onFlexChanged;

  const ResizableSplitView({
    super.key,
    required this.children,
    required this.flexValues,
    required this.onFlexChanged,
  });

  @override
  State<ResizableSplitView> createState() => _ResizableSplitViewState();
}

class _ResizableSplitViewState extends State<ResizableSplitView> {
  final ValueNotifier<double?> _dragPositionNotifier = ValueNotifier(null);
  int? _draggingDividerIndex;
  double? _dragStartX;
  double? _totalWidth;

  @override
  void dispose() {
    _dragPositionNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _totalWidth = constraints.maxWidth;
        final totalFlex = widget.flexValues.reduce((a, b) => a + b);

        List<Widget> rowChildren = [];

        for (int i = 0; i < widget.children.length; i++) {
          // Add the pane
          rowChildren.add(
            Expanded(
              flex: (widget.flexValues[i] * 1000).toInt(),
              child: widget.children[i],
            ),
          );

          // Add divider if not the last item
          if (i < widget.children.length - 1) {
            rowChildren.add(
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragStart: (details) {
                  _draggingDividerIndex = i;
                  _dragStartX = details.globalPosition.dx;
                  _dragPositionNotifier.value = 0; // Relative change
                },
                onHorizontalDragUpdate: (details) {
                  if (_dragStartX == null) return;
                  _dragPositionNotifier.value =
                      details.globalPosition.dx - _dragStartX!;
                },
                onHorizontalDragEnd: (details) {
                  if (_draggingDividerIndex != null &&
                      _dragPositionNotifier.value != null &&
                      _totalWidth != null) {
                    final delta = _dragPositionNotifier.value!;

                    // Calculate flex change based on width
                    final flexChange = (delta / _totalWidth!) * totalFlex;

                    final leftIndex = _draggingDividerIndex!;
                    final rightIndex = leftIndex + 1;

                    double newLeftFlex =
                        widget.flexValues[leftIndex] + flexChange;
                    double newRightFlex =
                        widget.flexValues[rightIndex] - flexChange;

                    // Enforce minimum size (e.g., 10% of total flex)
                    final minFlex = totalFlex * 0.1;

                    if (newLeftFlex < minFlex) {
                      final diff = minFlex - newLeftFlex;
                      newLeftFlex = minFlex;
                      newRightFlex -= diff;
                    } else if (newRightFlex < minFlex) {
                      final diff = minFlex - newRightFlex;
                      newRightFlex = minFlex;
                      newLeftFlex -= diff;
                    }

                    widget.onFlexChanged(leftIndex, newLeftFlex);
                    widget.onFlexChanged(rightIndex, newRightFlex);
                  }

                  _draggingDividerIndex = null;
                  _dragPositionNotifier.value = null;
                  _dragStartX = null;
                },
                onHorizontalDragCancel: () {
                  _draggingDividerIndex = null;
                  _dragPositionNotifier.value = null;
                  _dragStartX = null;
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeColumn,
                  child: Container(
                    width: 12, // Hit area
                    color: Colors.transparent,
                    child: Center(
                      child: Container(
                        width: 4, // Visible line
                        height: double.infinity,
                        decoration: BoxDecoration(
                          color: Theme.of(context).dividerColor,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 2,
                              offset: const Offset(1, 0),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }
        }

        return Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: rowChildren,
            ),
            // Render drag overlay line
            ValueListenableBuilder<double?>(
              valueListenable: _dragPositionNotifier,
              builder: (context, currentDragPosition, child) {
                if (_draggingDividerIndex == null ||
                    currentDragPosition == null) {
                  return const SizedBox.shrink();
                }
                return Positioned(
                  left:
                      _calculateDividerPosition(
                        _draggingDividerIndex!,
                        _totalWidth!,
                        totalFlex,
                      ) +
                      currentDragPosition -
                      2, // Center the 4px line
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 4,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.5),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  double _calculateDividerPosition(
    int dividerIndex,
    double totalWidth,
    double totalFlex,
  ) {
    // Total available width for Expanded = totalWidth - (numberOfDividers * 12)
    final numberOfDividers = widget.children.length - 1;
    final availableWidth = totalWidth - (numberOfDividers * 12);

    double pos = 0;
    for (int i = 0; i <= dividerIndex; i++) {
      pos += (widget.flexValues[i] / totalFlex) * availableWidth;
      if (i < dividerIndex) {
        pos += 12;
      }
    }
    // Now we are at the start of the divider at dividerIndex
    // Add half divider width to center
    pos += 6;
    return pos;
  }
}
