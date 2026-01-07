import 'package:flutter/widgets.dart';

import '../theme/panel_theme.dart';

/// A draggable handle widget used to resize adjacent panels.
///
/// This widget renders a transparent hit target that becomes visible (or highlights)
/// when hovered or dragged. It captures drag gestures and reports the delta
/// back to the parent [PanelArea].
class PanelResizeHandle extends StatefulWidget {
  /// Creates a [PanelResizeHandle].
  const PanelResizeHandle({
    required this.onDragUpdate,
    this.axis = Axis.vertical,
    this.onDragStart,
    this.onDragEnd,
    super.key,
  });

  /// Callback called when the handle is dragged.
  final ValueChanged<double> onDragUpdate;

  /// The axis of the layout (direction of the separator).
  final Axis axis;

  /// Optional callback called when dragging starts.
  final VoidCallback? onDragStart;

  /// Optional callback called when dragging ends.
  final VoidCallback? onDragEnd;

  @override
  State<PanelResizeHandle> createState() => _PanelResizeHandleState();
}

class _PanelResizeHandleState extends State<PanelResizeHandle> {
  bool _isHovered = false;
  bool _isDragging = false;

  @override
  Widget build(BuildContext context) {
    final theme = PanelTheme.of(context);
    final isVertical = widget.axis == Axis.vertical;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: isVertical
          ? SystemMouseCursors.resizeColumn
          : SystemMouseCursors.resizeRow,
      child: GestureDetector(
        onPanStart: (_) {
          setState(() => _isDragging = true);
          widget.onDragStart?.call();
        },
        onPanUpdate: (details) {
          widget.onDragUpdate(isVertical ? details.delta.dx : details.delta.dy);
        },
        onPanEnd: (_) {
          setState(() => _isDragging = false);
          widget.onDragEnd?.call();
        },
        behavior: HitTestBehavior.translucent,
        child: Container(
          // Hit target size (larger than visible line)
          width: isVertical ? theme.resizeHandleHitTestWidth : double.infinity,
          height: isVertical ? double.infinity : theme.resizeHandleHitTestWidth,
          color: const Color(0x00000000), // Colors.transparent
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              // Visible line size
              width: isVertical
                  ? (_isHovered || _isDragging ? theme.resizeHandleWidth : 1.0)
                  : double.infinity,
              height: isVertical
                  ? double.infinity
                  : (_isHovered || _isDragging ? theme.resizeHandleWidth : 1.0),
              decoration: _isDragging
                  ? (theme.resizeHandleActiveDecoration ??
                        BoxDecoration(
                          color: theme.resizeHandleActiveColor,
                          borderRadius: BorderRadius.circular(2),
                        ))
                  : (_isHovered
                        ? (theme.resizeHandleHoverDecoration ??
                              BoxDecoration(
                                color: theme.resizeHandleHoverColor,
                                borderRadius: BorderRadius.circular(2),
                              ))
                        : (theme.resizeHandleDecoration ??
                              BoxDecoration(
                                color: theme.resizeHandleColor,
                                borderRadius: BorderRadius.circular(2),
                              ))),
            ),
          ),
        ),
      ),
    );
  }
}
