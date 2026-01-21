import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import '../models/panel_id.dart';
import '../models/panel_enums.dart';
import '../layout/panel_layout_config.dart';
import 'inline_panel.dart';
import 'panel_toggle_button.dart';

/// An abstract configuration class for panels in a [PanelLayout].
///
/// **Do not implement this class directly.** Instead, use one of the concrete implementations:
/// - [InlinePanel]: For panels that share space in a linear layout (Row/Column).
/// - [OverlayPanel]: For floating panels that sit on top of others.
///
/// This class defines the shared properties for identification, initial state,
/// and basic visual styling (header, icon, background).
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
    this.sizeDuration,
    this.fadeDuration,
    this.animationCurve,
    this.title,
    this.titleStyle,
    this.headerHeight,
    this.headerPadding,
    this.icon,
    this.iconSize,
    this.iconColor,
    this.panelBoxDecoration,
    this.headerDecoration,
    super.key,
  });

  /// The unique identifier for this panel.
  ///
  /// Required for state management (visibility, collapsing) and layout linkage.
  final PanelId id;

  /// The content to display within the panel.
  final Widget child;

  /// The edge or direction to which the panel is logically anchored.
  ///
  /// - For [InlinePanel]: Determines the resize handle position and collapse animation.
  /// - For [OverlayPanel]: Determines where the panel is positioned relative to its target.
  final PanelAnchor anchor;

  /// The ID of another panel to anchor this one to.
  ///
  /// If provided, this panel will try to position itself relative to the target panel.
  final PanelId? anchorTo;

  /// The initial fixed width of the panel.
  /// Use this for fixed-size panels.
  final double? width;

  /// The initial fixed height of the panel.
  /// Use this for fixed-size panels.
  final double? height;

  /// Whether the panel is initially visible when the layout is first built.
  final bool initialVisible;

  /// Whether the panel is initially collapsed (minimized) when the layout is first built.
  final bool initialCollapsed;

  /// Optional override for the duration of size/visibility animations.
  /// If provided, this overrides the controller's total duration.
  final Duration? animationDuration;

  /// Optional override for the duration of the size change (slide) animation.
  /// If null, defaults to [PanelLayoutConfig.sizeDuration].
  final Duration? sizeDuration;

  /// Optional override for the duration of the opacity change (fade) animation.
  /// If null, defaults to [PanelLayoutConfig.fadeDuration].
  final Duration? fadeDuration;

  /// Optional override for the curve of size/visibility animations.
  final Curve? animationCurve;

  /// The title to display in the header.
  ///
  /// If null, no header text is shown.
  final String? title;

  /// Text style override for the header title.
  final TextStyle? titleStyle;

  /// The height of the panel header.
  ///
  /// If null, the height is automatically calculated using [headerPadding]
  /// (or [PanelLayoutConfig.headerPadding]) and the icon size.
  final double? headerHeight;

  /// Vertical padding for the header.
  ///
  /// If null, defaults to [PanelLayoutConfig.headerPadding].
  final double? headerPadding;

  /// The primary icon for the panel.
  ///
  /// **Important:** To use the built-in rotation animations for collapse/expand,
  /// you must provide a **Left-Pointing Chevron** (e.g., `Icons.chevron_left`).
  /// The system automatically rotates this icon based on the panel's anchor and state.
  ///
  /// Displayed in the header (if present) and in the collapsed rail (for [InlinePanel]).
  final Widget? icon;

  /// Size override for the icon.
  final double? iconSize;

  /// Color override for the icon.
  final Color? iconColor;

  /// Decoration for the panel container (background, border, shadow).
  ///
  /// If null, defaults to [PanelLayoutConfig.panelBoxDecoration].
  final BoxDecoration? panelBoxDecoration;

  /// Decoration for the header.
  final BoxDecoration? headerDecoration;

  /// Handles the action when the header icon is tapped.
  ///
  /// Implementations define whether this toggles collapse or visibility.
  @protected
  void onHeaderIconTap(BuildContext context);

  /// Builds the internal layout of the panel (wrapping content with header if needed).
  @protected
  Widget buildPanelLayout(BuildContext context, Widget? header, Widget content);

  /// Builds the header row content (Icon + Title).
  ///
  /// Used by [BasePanel] for the expanded state and by [AnimatedPanel]
  /// for the rail state (when [InlinePanel.showTitleInRail] is true).
  @internal
  Widget buildHeaderRow(BuildContext context, PanelLayoutConfig config) {
    final effectiveIconSize = iconSize ?? config.iconSize;

    // UX Logic for Icon Placement:
    // The icon should be placed on the "opening side" of the panel.
    PanelAnchor effectiveClosingDir = anchor;
    if (this is InlinePanel) {
      effectiveClosingDir = (this as InlinePanel).closingDirection ?? anchor;
    }

    final bool showIconOnLeft = effectiveClosingDir == PanelAnchor.right;

    return Row(
      children: [
        // If anchored Right (closes right), show icon first (on the left edge)
        if (showIconOnLeft && icon != null) ...[
          PanelToggleButton(
            icon: icon!,
            size: effectiveIconSize,
            color: iconColor ?? config.iconColor,
            onTap: () => onHeaderIconTap(context),
            shouldRotate: (this is InlinePanel)
                ? (this as InlinePanel).rotateIcon
                : false,
            closingDirection: (this is InlinePanel)
                ? (this as InlinePanel).closingDirection
                : null,
            panelId: id,
          ),
          if (title != null) const SizedBox(width: 8),
        ],

        if (title != null)
          Expanded(
            child: Text(
              title!,
              style: titleStyle ?? config.titleStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),

        // If anchored Left/Top/Bottom, show icon last (on the right edge)
        if (!showIconOnLeft && icon != null) ...[
          if (title != null) const SizedBox(width: 8),
          PanelToggleButton(
            icon: icon!,
            size: effectiveIconSize,
            color: iconColor ?? config.iconColor,
            onTap: () => onHeaderIconTap(context),
            shouldRotate: (this is InlinePanel)
                ? (this as InlinePanel).rotateIcon
                : false,
            closingDirection: (this is InlinePanel)
                ? (this as InlinePanel).closingDirection
                : null,
            panelId: id,
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (title == null && icon == null && panelBoxDecoration == null) {
      return child;
    }

    final config = PanelConfigurationScope.of(context);
    final effectiveDecoration = panelBoxDecoration ?? config.panelBoxDecoration;

    Widget? header;
    if (title != null || icon != null) {
      final effectiveHeaderDecoration =
          headerDecoration ?? config.headerDecoration;

      final effectiveIconSize = iconSize ?? config.iconSize;
      final effectivePadding = headerPadding ?? config.headerPadding;
      final effectiveHeaderHeight =
          headerHeight ?? (effectiveIconSize + (effectivePadding * 2));

      header = Container(
        key: Key('panel_header_${id.value}'),
        height: effectiveHeaderHeight,
        decoration: effectiveHeaderDecoration,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: buildHeaderRow(context, config),
      );
    }

    return Container(
      decoration: effectiveDecoration,
      clipBehavior: effectiveDecoration != null ? Clip.antiAlias : Clip.none,
      child: buildPanelLayout(context, header, child),
    );
  }
}
