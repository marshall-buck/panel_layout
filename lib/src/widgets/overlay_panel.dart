import 'package:flutter/widgets.dart';
import '../models/panel_enums.dart';
import 'base_panel.dart';

/// A panel that floats on top of the layout (Overlay).
///
/// Overlay panels do not affect the layout of inline panels.
class OverlayPanel extends BasePanel {
  const OverlayPanel({
    required super.id,
    required super.child,
    super.anchor = PanelAnchor.left,
    super.anchorTo,
    super.width,
    super.height,
    super.toggleIcon,
    super.closingDirection,
    super.collapsedDecoration,
    super.initialVisible = true,
    super.initialCollapsed = true, // Default to true as requested
    super.animationDuration,
    super.animationCurve,
    this.anchorLink,
    this.zIndex = 0,
    this.alignment,
    this.crossAxisAlignment,
    super.key,
  });

  /// A layer link to anchor this panel to an external widget.
  final LayerLink? anchorLink;

  /// The z-index paint order (higher values paint on top).
  final int zIndex;

  /// Alignment for overlay positioning.
  final AlignmentGeometry? alignment;

  /// Cross-axis behavior for layout.
  final CrossAxisAlignment? crossAxisAlignment;
}
