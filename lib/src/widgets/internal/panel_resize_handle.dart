import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';

import '../../layout/panel_style.dart';

/// A draggable handle widget used to resize adjacent panels.
///
/// This widget renders a transparent hit target that captures drag gestures
/// and reports the delta back to the parent [PanelLayout].
///
/// It does not manage size state itself; it only invokes callbacks.
@internal
class PanelResizeHandle extends StatelessWidget {
  /// Creates a [PanelResizeHandle].
  const PanelResizeHandle({
    required this.onDragUpdate,
    this.axis = Axis.vertical,
    this.resizable = true,
    this.onDragStart,
    this.onDragEnd,
    super.key,
  });

  /// Callback called when the handle is dragged.
  final ValueChanged<double> onDragUpdate;

  /// The axis of the layout (direction of the separator).
  final Axis axis;

  /// Whether the handle is currently active for resizing.
  final bool resizable;

  /// Optional callback called when dragging starts.
  final VoidCallback? onDragStart;

  /// Optional callback called when dragging ends.
  final VoidCallback? onDragEnd;

  @override
  Widget build(BuildContext context) {
    final config = PanelConfigurationScope.of(context);
    final isVertical = axis == Axis.vertical;

    return MouseRegion(
      cursor: resizable
          ? (isVertical
                ? SystemMouseCursors.resizeColumn
                : SystemMouseCursors.resizeRow)
          : MouseCursor.defer,
      child: GestureDetector(
        onPanStart: resizable ? (_) => onDragStart?.call() : null,
        onPanUpdate: resizable
            ? (details) {
                onDragUpdate(isVertical ? details.delta.dx : details.delta.dy);
              }
            : null,
        onPanEnd: resizable ? (_) => onDragEnd?.call() : null,
        behavior: HitTestBehavior.translucent,
        child: Container(
          // Hit target size (larger than visible line)
          width: isVertical ? config.handleHitTestWidth : double.infinity,
          height: isVertical ? double.infinity : config.handleHitTestWidth,
          color: const Color(0x00000000), // Colors.transparent
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Visible line
              Container(
                width: isVertical ? config.handleWidth : double.infinity,
                height: isVertical ? double.infinity : config.handleWidth,
                decoration: BoxDecoration(color: config.handleColor),
              ),
              // Icon/Grip
              if (resizable && config.handleIcon != null)
                Align(
                  alignment: config.handleIconAlignment,
                  child: Icon(
                    config.handleIcon,
                    size: config.handleIconSize,
                    color: config.handleIconColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
