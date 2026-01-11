import 'package:flutter/widgets.dart';

import '../models/panel_id.dart';
import '../models/panel_enums.dart';

/// An abstract base class for panels in a [PanelLayout].
///
/// Users should extend this class to create their own panels.
/// [PanelLayout] uses the properties defined here to calculate layout and behavior.
abstract class BasePanel extends StatelessWidget {
  /// Creates a declarative panel configuration.
  const BasePanel({
    required this.id,
    required this.child,
    this.mode = PanelMode.inline,
    this.anchor = PanelAnchor.left,
    this.anchorTo,
    this.anchorLink,
    this.width,
    this.height,
    this.flex,
    this.minSize,
    this.maxSize,
    this.collapsedSize,
    this.resizable = true,
    this.initialVisible = true,
    this.initialCollapsed = false,
    this.zIndex = 0,
    this.animationDuration,
    this.animationCurve,
    this.alignment,
    this.crossAxisAlignment,
    super.key,
  }) : assert(
         (width != null || height != null) ? flex == null : true,
         'Cannot provide both fixed size (width/height) and flex.',
       );

  /// The unique identifier for this panel.
  final PanelId id;

  /// The content to display within the panel.
  final Widget child;

  /// The display mode of the panel (e.g., docked vs. overlay).
  final PanelMode mode;

  /// The edge or direction to which the panel is anchored.
  final PanelAnchor anchor;

  /// The ID of another panel to anchor this one to (for relative overlays).
  final PanelId? anchorTo;

  /// A layer link to anchor this panel to an external widget.
  final LayerLink? anchorLink;

  /// The initial fixed width of the panel. Use this or [flex], not both.
  final double? width;

  /// The initial fixed height of the panel. Use this or [flex], not both.
  final double? height;

  /// The flex factor for fluid sizing. Use this or [width]/[height], not both.
  final double? flex;

  /// The minimum size (width or height) the panel can be resized to.
  final double? minSize;

  /// The maximum size (width or height) the panel can be resized to.
  final double? maxSize;

  /// The size of the panel when collapsed. Defaults to 0.0.
  final double? collapsedSize;

  /// Whether the panel can be resized by the user.
  final bool resizable;

  /// Whether the panel is initially visible.
  final bool initialVisible;

  /// Whether the panel is initially collapsed.
  final bool initialCollapsed;

  /// The z-index paint order (higher values paint on top).
  final int zIndex;

  /// Optional override for animation duration.
  final Duration? animationDuration;

  /// Optional override for animation curve.
  final Curve? animationCurve;

  /// Alignment for overlay positioning.
  final AlignmentGeometry? alignment;

  /// Cross-axis behavior for layout.
  final CrossAxisAlignment? crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
