import 'package:flutter/widgets.dart';
import '../models/panel_id.dart';
import '../models/panel_enums.dart';
import '../theme/panel_theme.dart';
import '../state/panel_scope.dart';

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
    this.toggleIcon,
    this.closingDirection,
    this.collapsedDecoration,
    this.initialVisible = true,
    required this.initialCollapsed,
    this.animationDuration,
    this.animationCurve,
    this.title,
    this.headerIcon,
    this.decoration,
    this.headerDecoration,
    this.headerTextStyle,
    this.headerIconColor,
    this.headerIconSize,
    this.headerAction,
    this.rotateToggleIcon = true,
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

  /// The title to display in the header.
  /// If null, no header is shown unless [headerIcon] is provided.
  final String? title;

  /// The action icon to display in the header (e.g., close/toggle).
  final Widget? headerIcon;

  /// Decoration for the panel container.
  final BoxDecoration? decoration;

  /// Decoration override for the header.
  final BoxDecoration? headerDecoration;

  /// Text style override for the header title.
  final TextStyle? headerTextStyle;

  /// Color override for the header icon.
  final Color? headerIconColor;

  /// Size override for the header icon.
  final double? headerIconSize;

  /// The action to perform when the [headerIcon] is pressed.
  /// If null, defaults to [PanelAction.collapse] for InlinePanels and
  /// [PanelAction.close] for OverlayPanels.
  final PanelAction? headerAction;

  /// Whether the [toggleIcon] should rotate automatically based on the panel anchor.
  /// Defaults to true.
  final bool rotateToggleIcon;

  /// Determines if this panel is an overlay.
  /// Used to decide default icon behavior (close vs toggle).
  bool get isOverlay;

  @override
  Widget build(BuildContext context) {
    if (title == null && headerIcon == null && decoration == null) {
      return child;
    }

    final theme = PanelTheme.of(context);
    final effectiveDecoration = decoration ?? theme.panelDecoration;

    Widget? header;
    if (title != null || headerIcon != null) {
      header = Container(
        height: theme.headerHeight,
        decoration: headerDecoration ?? theme.headerDecoration,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            if (title != null)
              Expanded(
                child: Text(
                  title!,
                  style: headerTextStyle ?? theme.headerTextStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (headerIcon != null) ...[
              if (title != null) const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  final controller = PanelScope.of(context);

                  final effectiveAction =
                      headerAction ??
                      (isOverlay ? PanelAction.close : PanelAction.collapse);

                  switch (effectiveAction) {
                    case PanelAction.collapse:
                      controller.toggleCollapsed(id);
                      break;
                    case PanelAction.close:
                      controller.setVisible(id, false);
                      break;
                    case PanelAction.none:
                      break;
                  }
                },
                child: IconTheme(
                  data: IconThemeData(
                    size: headerIconSize ?? theme.headerIconSize,
                    color: headerIconColor ?? theme.headerIconColor,
                  ),
                  child: headerIcon!,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      decoration: effectiveDecoration,
      clipBehavior: effectiveDecoration != null ? Clip.antiAlias : Clip.none,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: isOverlay ? MainAxisSize.min : MainAxisSize.max,
        children: [
          if (header != null) header,
          if (isOverlay)
            child // Overlay panels size to content (or fixed size via parent), no expansion logic needed to avoid unbounded errors.
          else
            Expanded(child: child), // Inline panels fill their slot.
        ],
      ),
    );
  }
}
