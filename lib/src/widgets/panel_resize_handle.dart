import 'package:flutter/widgets.dart';

import '../theme/resize_handle_theme.dart';

/// A draggable handle widget used to resize adjacent panels.
///
/// This widget renders a transparent hit target that captures drag gestures
/// and reports the delta back to the parent [PanelLayout].
class PanelResizeHandle extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = ResizeHandleTheme.of(context);
    final isVertical = axis == Axis.vertical;

    return MouseRegion(
      cursor: isVertical
          ? SystemMouseCursors.resizeColumn
          : SystemMouseCursors.resizeRow,
      child: GestureDetector(
        onPanStart: (_) => onDragStart?.call(),
        onPanUpdate: (details) {
          onDragUpdate(isVertical ? details.delta.dx : details.delta.dy);
        },
        onPanEnd: (_) => onDragEnd?.call(),
        behavior: HitTestBehavior.translucent,
        child: Container(
          // Hit target size (larger than visible line)
          width: isVertical ? theme.hitTestWidth : double.infinity,
          height: isVertical ? double.infinity : theme.hitTestWidth,
          color: const Color(0x00000000), // Colors.transparent
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Visible line
              Container(
                width: isVertical ? theme.width : double.infinity,
                height: isVertical ? double.infinity : theme.width,
                decoration: BoxDecoration(
                  color: theme.color,
                ),
              ),
              // Icon/Grip
              if (theme.icon != null)
                Align(
                  alignment: theme.iconAlignment,
                  child: Icon(
                    theme.icon,
                    size: theme.iconSize,
                    color: theme.iconColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}