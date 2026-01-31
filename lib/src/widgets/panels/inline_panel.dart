import 'package:flutter/widgets.dart';
import '../../models/panel_enums.dart';
import '../../state/panel_scope.dart';
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
    super.anchor,
    super.anchorTo,
    super.width,
    super.height,
    this.minSize,
    this.maxSize,
    this.railIconAlignment,
    this.closingDirection,
    this.railDecoration,
    this.resizable = true,
    this.action = PanelAction.collapse,

    /// Whether the panel is initially visible.
    super.initialVisible = true,

    /// Whether the panel is initially collapsed into a rail.
    super.initialCollapsed = false,
    super.preserveLayoutState = false,
    super.animationDuration,
    super.animationCurve,
    super.title,
    super.titleStyle,
    super.headerHeight,
    super.headerPadding,

    /// The primary icon for the panel.
    ///
    /// **Important:** To use the built-in rotation animations, provide a **Left-Pointing Chevron**
    /// (e.g., `Icons.chevron_left`). The system automatically rotates this icon.
    super.icon,
    super.iconSize,
    super.iconColor,
    super.panelBoxDecoration,
    super.headerDecoration,
    this.railPadding,
    this.rotateIcon = true,
    this.showTitleInRail = true,
    super.clipContent = false,
    super.key,
  });

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

  /// The action to perform when the header icon is tapped.
  /// Defaults to [PanelAction.collapse].
  final PanelAction action;

  /// The direction the panel moves when closing (collapsing).
  ///
  /// Used to determine the rotation of the icon in the rail.
  /// If null, defaults to [anchor].
  final PanelAnchor? closingDirection;

  /// Decoration for the collapsed strip container (e.g. background color).
  final BoxDecoration? railDecoration;

  /// Padding around the icon in the collapsed rail.
  final double? railPadding;

  /// Whether the icon should rotate automatically in the rail based on the panel anchor.
  /// Defaults to true.
  final bool rotateIcon;

  /// Whether to show the panel title (if available) when the panel is collapsed into a rail.
  ///
  /// Useful for Top/Bottom panels where the rail is a horizontal strip that can accommodate text.
  /// Defaults to true.
  final bool showTitleInRail;

  @override
  bool get shouldRotate => rotateIcon;

  @override
  PanelAnchor? get effectiveClosingDirection => closingDirection ?? anchor;

  @override
  void onHeaderIconTap(BuildContext context) {
    switch (action) {
      case PanelAction.collapse:
        PanelScope.of(context).toggleCollapsed(id);
        break;
      case PanelAction.close:
        PanelScope.of(context).setVisible(id, false);
        break;
      case PanelAction.none:
        break;
    }
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
        ?header,
        Expanded(child: clipContent ? ClipRect(child: content) : content),
      ],
    );
  }
}
