import 'package:flutter/widgets.dart';
import '../models/panel_enums.dart';
import '../state/panel_scope.dart';
import 'base_panel.dart';

/// A panel that participates in the linear layout (Row/Column).
///
/// Inline panels are tiled next to each other. They can be:
/// - **Fixed**: Specific [width] or [height].
/// - **Flexible**: Takes up remaining space based on [flex].
/// - **Content Sized**: Sized to its content if both fixed and flex are null.
///
/// Inline panels can be **collapsed** into a thin "rail" showing only the icon.
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
    this.railIconAlignment,
    this.closingDirection,
    this.railDecoration,
    this.resizable = true,
    /// Whether the panel is initially visible.
    super.initialVisible = true,
    /// Whether the panel is initially collapsed into a rail.
    super.initialCollapsed = false,
    super.animationDuration,
    super.animationCurve,
    super.title,
    super.titleStyle,
    super.icon,
    super.iconSize,
    super.iconColor,
    super.panelBoxDecoration,
    super.headerDecoration,
    this.rotateIcon = true,
    super.key,
  }) : assert(
         (width != null || height != null) ? flex == null : true,
         'Cannot provide both fixed size (width/height) and flex.',
       );

  /// The flex factor for fluid sizing.
  ///
  /// If non-null, the panel will expand to fill available space relative to other flexible panels.
  /// Use this OR [width]/[height], not both.
  final double? flex;

  /// The minimum size (width or height) the panel can be resized to by the user.
  final double? minSize;

  /// The maximum size (width or height) the panel can be resized to by the user.
  final double? maxSize;

  /// The alignment of the icon within the collapsed strip.
  ///
  /// If null, it is automatically determined by the panel's [anchor]:
  /// - Top/Bottom anchors: [Alignment.centerRight] (usually).
  /// - Left/Right anchors: [Alignment.topCenter].
  final Alignment? railIconAlignment;

  /// Whether the panel can be manually resized by the user (via drag handle).
  final bool resizable;

  /// The direction the panel moves when closing (collapsing).
  ///
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