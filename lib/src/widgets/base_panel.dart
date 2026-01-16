import 'package:flutter/widgets.dart';
import '../models/panel_id.dart';
import '../models/panel_enums.dart';

/// An abstract base class for panels in a [PanelLayout].
///
/// Defines properties shared by both [InlinePanel] and [OverlayPanel].
abstract class BasePanel extends StatelessWidget {
  const BasePanel({
    required this.id,
    required this.child,
    this.anchor = PanelAnchor.left,
    this.anchorTo,
    this.width,
    this.height,
    this.collapsedSize,
    this.toggleIcon,
    this.closingDirection,
    this.collapsedDecoration,
    this.initialVisible = true,
    required this.initialCollapsed,
    this.animationDuration,
    this.animationCurve,
    super.key,
  });

  /// The unique identifier for this panel.
  final PanelId id;

  /// The content to display within the panel.
  final Widget child;

  /// The edge or direction to which the panel is anchored.
  final PanelAnchor anchor;

  /// The ID of another panel to anchor this one to.
  final PanelId? anchorTo;

  /// The initial fixed width of the panel.
  final double? width;

  /// The initial fixed height of the panel.
  final double? height;

  /// The size of the panel when collapsed.
  final double? collapsedSize;

  /// The icon to display when collapsed.
  /// If provided, a toggle button will be rendered in the collapsed strip.
  /// This should be a left-pointing chevron for correct rotation logic.
  final Widget? toggleIcon;

  /// The direction the panel moves when closing.
  /// Used to determine the rotation of the [toggleIcon].
  /// If null, defaults to [anchor].
  final PanelAnchor? closingDirection;

  /// Decoration for the collapsed strip container (e.g. background color).
  final BoxDecoration? collapsedDecoration;

  /// Whether the panel is initially visible.
  final bool initialVisible;

  /// Whether the panel is initially collapsed.
  final bool initialCollapsed;

  /// Optional override for animation duration.
  final Duration? animationDuration;

  /// Optional override for animation curve.
  final Curve? animationCurve;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}
