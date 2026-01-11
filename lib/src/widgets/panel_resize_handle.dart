import 'package:flutter/widgets.dart';

import '../constants.dart';
import '../theme/resize_handle_theme.dart';

/// A draggable handle widget used to resize adjacent panels.
///
/// This widget renders a transparent hit target that becomes visible (or highlights)
/// when hovered or dragged. It captures drag gestures and reports the delta
/// back to the parent [PanelLayout].
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
    // Resolve Theme (New Theme only)
    final theme = ResizeHandleTheme.of(context);
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
          width: isVertical ? theme.hitTestWidth : double.infinity,
          height: isVertical ? double.infinity : theme.hitTestWidth,
          color: const Color(0x00000000), // Colors.transparent
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Visible line
              AnimatedContainer(
                duration: kDefaultHoverDuration,
                width: isVertical
                    ? (_isHovered || _isDragging ? theme.width : 1.0)
                    : double.infinity,
                height: isVertical
                    ? double.infinity
                    : (_isHovered || _isDragging ? theme.width : 1.0),
                decoration: _getDecoration(theme),
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

  Decoration _getDecoration(ResizeHandleThemeData theme) {
    if (_isDragging) {
      return theme.activeDecoration ??
          BoxDecoration(
            color: theme.activeColor,
            border: theme.borderColor != null
                ? Border.all(color: theme.borderColor!, width: theme.borderWidth ?? 1.0)
                : null,
            borderRadius: BorderRadius.circular(theme.borderRadius ?? 2.0),
          );
    }

    if (_isHovered) {
      return theme.hoverDecoration ??
          BoxDecoration(
            color: theme.hoverColor,
            border: theme.borderColor != null
                ? Border.all(color: theme.borderColor!, width: theme.borderWidth ?? 1.0)
                : null,
            borderRadius: BorderRadius.circular(theme.borderRadius ?? 2.0),
          );
    }

    return theme.decoration ??
        BoxDecoration(
          color: theme.color,
          border: theme.borderColor != null
              ? Border.all(color: theme.borderColor!, width: theme.borderWidth ?? 1.0)
              : null,
          borderRadius: BorderRadius.circular(theme.borderRadius ?? 2.0),
        );
  }
}
