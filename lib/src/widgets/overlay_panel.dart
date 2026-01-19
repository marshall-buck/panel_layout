import 'package:flutter/widgets.dart';
import '../models/panel_enums.dart';
import '../state/panel_scope.dart';
import 'base_panel.dart';

/// A panel that floats on top of the layout (Overlay).
///
/// Overlay panels do not affect the flow of inline panels. They are positioned
/// absolutely, either relative to the entire layout, relative to another panel ([anchorTo]),
/// or tracked via a [LayerLink].
class OverlayPanel extends BasePanel {
  const OverlayPanel({
    required super.id,
    required super.child,
    super.anchor = PanelAnchor.left,
    super.anchorTo,
    super.width,
    super.height,
    /// Whether the overlay is initially visible.
    super.initialVisible = true,
    super.animationDuration,
    super.animationCurve,
    this.anchorLink,
    this.zIndex = 0,
    this.alignment,
    this.crossAxisAlignment,
    super.title,
    super.titleStyle,
    super.icon,
    super.iconSize,
    super.iconColor,
    super.decoration,
    super.headerColor,
    super.headerBorder,
    super.key,
  }) : super(initialCollapsed: false);

  /// A layer link to anchor this panel to an external widget anywhere in the tree.
  ///
  /// If provided, [anchorTo] is ignored, and the panel is composited relative to the link leader.
  final LayerLink? anchorLink;

  /// The z-index paint order (higher values paint on top).
  ///
  /// Useful when multiple overlays overlap.
  final int zIndex;

  /// Alignment for overlay positioning.
  ///
  /// If [anchorTo] is null, this aligns the panel within the global layout area.
  /// If [anchorTo] is set, this aligns the panel relative to the target's edge.
  final AlignmentGeometry? alignment;

  /// Cross-axis behavior for layout.
  ///
  /// If set to [CrossAxisAlignment.stretch], the panel will stretch to match the
  /// size of its [anchorTo] target along the cross axis (e.g., width for a top/bottom anchor).
  final CrossAxisAlignment? crossAxisAlignment;

  @override
  void onHeaderIconTap(BuildContext context) {
    PanelScope.of(context).setVisible(id, false);
  }

  @override
  Widget buildPanelLayout(
    BuildContext context,
    Widget? header,
    Widget content,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (header != null) header,
        content,
      ],
    );
  }
}
