import 'package:flutter/widgets.dart';
import '../models/panel_enums.dart';
import '../state/panel_scope.dart';
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
    this.railIconAlignment,
    this.closingDirection,
    this.railDecoration,
    this.resizable = true,
    super.initialVisible = true,
    super.initialCollapsed = false,
    super.animationDuration,
    super.animationCurve,
    super.title,
    super.titleStyle,
    super.icon,
    super.iconSize,
    super.iconColor,
    super.decoration,
    super.headerColor,
    super.headerBorder,
    this.rotateIcon = true,
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

  /// The size of the icon in the collapsed rail. Defaults to 24.0.
  final double toggleIconSize;

  /// The padding to add to the toggle icon size when calculating the collapsed panel size.
  /// Defaults to 1.0.
  final double toggleIconPadding;

  /// The alignment of the toggle icon within the collapsed strip.
  /// If null, it is automatically determined by the panel's anchor:
  /// - Top/Bottom anchors: [Alignment.centerLeft]
  /// - Left/Right anchors: [Alignment.topCenter]
  final Alignment? railIconAlignment;

  /// The size of the panel when collapsed.
  ///
  /// Calculated as [toggleIconSize] + [toggleIconPadding].
  double get collapsedSize => toggleIconSize + toggleIconPadding;

  /// Whether the panel can be resized by the user.
  final bool resizable;

  /// The direction the panel moves when closing.
  /// Used to determine the rotation of the icon in the rail.
  /// If null, defaults to [anchor].
  final PanelAnchor? closingDirection;

  /// Decoration for the collapsed strip container (e.g. background color).
  final BoxDecoration? railDecoration;

  /// Whether the icon should rotate automatically in the rail based on the panel anchor.
  /// Defaults to true.
  final bool rotateIcon;

  @override
  void onHeaderIconTap(BuildContext context) {
    PanelScope.of(context).toggleCollapsed(id);
  }

  @override
  Widget buildPanelLayout(
    BuildContext context,
    Widget? header,
    Widget content,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.max,
      children: [
        if (header != null) header,
        Expanded(child: content),
      ],
    );
  }
}