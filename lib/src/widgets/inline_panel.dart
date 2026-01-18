import 'package:flutter/widgets.dart';
import '../models/panel_enums.dart';
import 'base_panel.dart';

/// A panel that participates in the linear layout (Row/Column).
///
/// Inline panels push other panels aside and can be resized or flexed.
class InlinePanel extends BasePanel {
  const InlinePanel({
    required super.id,
    required super.child,
    super.anchor = PanelAnchor.left,
    super.anchorTo,
    super.width,
    super.height,
    this.flex,
    this.minSize,
    this.maxSize,
    this.toggleIconSize = 24.0,
    this.toggleIconPadding = 1.0,
    this.toggleIconAlignment,
    super.toggleIcon,
    super.closingDirection,
    super.collapsedDecoration,
    this.resizable = true,
    super.initialVisible = true,
    super.initialCollapsed = false,
    super.animationDuration,
    super.animationCurve,
    super.title,
    super.headerIcon,
    super.decoration,
    super.headerDecoration,
    super.headerTextStyle,
    super.headerIconColor,
    super.headerIconSize,
    super.headerAction,
    super.rotateToggleIcon,
    super.key,
  }) : assert(
         (width != null || height != null) ? flex == null : true,
         'Cannot provide both fixed size (width/height) and flex.',
       );

  /// The flex factor for fluid sizing. Use this or [width]/[height], not both.
  final double? flex;

  /// The minimum size (width or height) the panel can be resized to.
  final double? minSize;

  /// The maximum size (width or height) the panel can be resized to.
  final double? maxSize;

  /// The size of the toggle icon. Defaults to 24.0.
  final double toggleIconSize;

  /// The padding to add to the toggle icon size when calculating the collapsed panel size.
  /// Defaults to 1.0.
  final double toggleIconPadding;

  /// The alignment of the toggle icon within the collapsed strip.
  /// If null, it is automatically determined by the panel's anchor:
  /// - Top/Bottom anchors: [Alignment.centerLeft]
  /// - Left/Right anchors: [Alignment.topCenter]
  final Alignment? toggleIconAlignment;

  /// The size of the panel when collapsed.
  ///
  /// Calculated as [toggleIconSize] + [toggleIconPadding].
  double get collapsedSize => toggleIconSize + toggleIconPadding;

  /// Whether the panel can be resized by the user.
  final bool resizable;

  @override
  bool get isOverlay => false;
}
