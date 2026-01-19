import 'package:flutter/widgets.dart';
import '../models/panel_id.dart';
import '../models/panel_enums.dart';
import '../theme/panel_theme.dart';
import 'inline_panel.dart';
import 'panel_toggle_button.dart';

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
    this.initialVisible = true,
    required this.initialCollapsed,
    this.animationDuration,
    this.animationCurve,
    this.title,
    this.titleStyle,
    this.icon,
    this.iconSize,
    this.iconColor,
    this.decoration,
    this.headerColor,
    this.headerBorder,
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

  /// Whether the panel is initially visible.
  final bool initialVisible;

  /// Whether the panel is initially collapsed.
  final bool initialCollapsed;

  /// Optional override for animation duration.
  final Duration? animationDuration;

  /// Optional override for animation curve.
  final Curve? animationCurve;

  /// The title to display in the header.
  /// If null, no header is shown unless [icon] is provided.
  final String? title;

  /// Text style override for the header title.
  final TextStyle? titleStyle;

  /// The primary icon for the panel (used in header and collapsed rail).
  final Widget? icon;

  /// Size override for the icon.
  final double? iconSize;

  /// Color override for the icon.
  final Color? iconColor;

  /// Decoration for the panel container.
  final BoxDecoration? decoration;

  /// Background color for the header.
  final Color? headerColor;

  /// Border for the header.
  final BoxBorder? headerBorder;

  /// Handles the action when the header icon is tapped.
  @protected
  void onHeaderIconTap(BuildContext context);

  /// Builds the internal layout of the panel (inside the styled Container).
  @protected
  Widget buildPanelLayout(BuildContext context, Widget? header, Widget content);

  @override
  Widget build(BuildContext context) {
    if (title == null && icon == null && decoration == null) {
      return child;
    }

    final theme = PanelTheme.of(context);
    final effectiveDecoration = decoration ?? theme.panelDecoration;

    Widget? header;
    if (title != null || icon != null) {
      final effectiveHeaderDecoration =
          (headerColor != null || headerBorder != null)
              ? BoxDecoration(color: headerColor, border: headerBorder)
              : theme.headerDecoration;

      header = Container(
        height: theme.headerHeight,
        decoration: effectiveHeaderDecoration,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            if (title != null)
              Expanded(
                child: Text(
                  title!,
                  style: titleStyle ?? theme.headerTextStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (icon != null) ...[
              if (title != null) const SizedBox(width: 8),
              // Use PanelToggleButton instead of GestureDetector for consistency.
              PanelToggleButton(
                icon: icon!,
                // Explicitly pass the header icon size.
                size: iconSize ?? theme.headerIconSize,
                color: iconColor ?? theme.headerIconColor,
                onTap: () => onHeaderIconTap(context),
                shouldRotate:
                    (this is InlinePanel)
                        ? (this as InlinePanel).rotateIcon
                        : false,
                closingDirection:
                    (this is InlinePanel)
                        ? (this as InlinePanel).closingDirection
                        : null,
                panelId: id,
              ),
            ],
          ],
        ),
      );
    }

    return Container(
      decoration: effectiveDecoration,
      clipBehavior: effectiveDecoration != null ? Clip.antiAlias : Clip.none,
      child: buildPanelLayout(context, header, child),
    );
  }
}
