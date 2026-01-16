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
    super.collapsedSize,
    super.collapsedChild,
    super.toggleIcon,
    this.resizable = true,
    super.initialVisible = true,
    super.initialCollapsed = false,
    super.animationDuration,
    super.animationCurve,
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

  /// Whether the panel can be resized by the user.
  final bool resizable;
}
