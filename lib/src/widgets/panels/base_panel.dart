import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import '../../models/panel_id.dart';
import '../../models/panel_enums.dart';
import '../../models/panel_style.dart';
import 'inline_panel.dart';
import '../internal/panel_toggle_button.dart';

/// An abstract configuration class for panels in a [PanelArea].
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
    this.anchor,
    this.anchorTo,
    this.width,
    this.height,
    this.initialVisible = true,
    required this.initialCollapsed,
    this.preserveLayoutState = false,
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
    this.clipContent = false,
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
  final PanelAnchor? anchor;

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

  /// Whether to preserve the panel's runtime layout state (size, visibility, collapse)
  /// when it is removed from the widget tree.
  ///
  /// If `true`, the panel will "remember" its user-adjusted size and state if it
  /// is removed (e.g., via conditional building in the parent) and re-added later.
  /// If `false` (default), the state is discarded when the panel is removed.
  final bool preserveLayoutState;

  /// Optional override for the duration of size/visibility animations.
  /// If provided, this overrides the controller's total duration.
  final Duration? animationDuration;

  /// Optional override for the duration of the size change (slide) animation.
  /// If null, defaults to [PanelStyle.sizeDuration].
  final Duration? sizeDuration;

  /// Optional override for the duration of the opacity change (fade) animation.
  /// If null, defaults to [PanelStyle.fadeDuration].
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
  /// (or [PanelStyle.headerPadding]) and the icon size.
  final double? headerHeight;

  /// Vertical padding for the header.
  ///
  /// If null, defaults to [PanelStyle.headerPadding].
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
  /// If null, defaults to [PanelStyle.panelBoxDecoration].
  final BoxDecoration? panelBoxDecoration;

  /// Decoration for the header.
  final BoxDecoration? headerDecoration;

  /// Whether to clip the content of the panel.
  ///
  /// If true, the panel content will be wrapped in a [ClipRect] to prevent
  /// visual overflow when the panel is resized smaller than its content.
  final bool clipContent;

  /// Whether the header icon should rotate when the panel state changes.
  @protected
  bool get shouldRotate;

  /// The logical direction the panel closes towards.
  @protected
  PanelAnchor? get effectiveClosingDirection;

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
  Widget buildHeaderRow(BuildContext context, PanelStyle config) {
    final effectiveIconSize = iconSize ?? config.iconSize;
    const double spacing = 8.0;

    // UX Logic for Icon Placement:
    // The icon should be placed on the "closing side" of the panel.
    final closingDir = effectiveClosingDirection ?? anchor;

    // If closes LEFT (<--), Icon should be on LEFT.
    // If closes RIGHT (-->), Icon should be on RIGHT.
    final bool showIconOnLeft = closingDir == PanelAnchor.left;

    Widget? toggleButton;
    if (icon != null) {
      toggleButton = PanelToggleButton(
        icon: icon!,
        size: effectiveIconSize,
        color: iconColor ?? config.iconColor,
        onTap: () => onHeaderIconTap(context),
        shouldRotate: shouldRotate,
        closingDirection: effectiveClosingDirection,
        panelId: id,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        // Calculate the minimum width required to show the full structure (Icon + Spacing)
        // If we have a title, we need the spacing. If only an icon, no spacing needed.
        final double requiredFixedSpace = (toggleButton != null)
            ? effectiveIconSize + (title != null ? spacing : 0.0)
            : 0.0;

        // If available space is too small for the fixed parts (Icon + Gap),
        // we switch to a fallback mode: Just show the Icon (clipped if needed), hide Title & Gap.
        if (availableWidth < requiredFixedSpace) {
          if (toggleButton != null) {
            return Align(
              alignment: showIconOnLeft
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              child: ClipRect(child: toggleButton),
            );
          }
          return const SizedBox();
        }

        return Row(
          children: [
            // If anchored Left (closes left), show icon first (on the left edge)
            if (showIconOnLeft && toggleButton != null) ...[
              toggleButton,
              if (title != null) const SizedBox(width: spacing),
            ],

            if (title != null)
              Expanded(
                child: Text(
                  title!,
                  style: titleStyle ?? config.titleTextStyle,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),

            // If anchored Right/Top/Bottom, show icon last (on the right edge)
            if (!showIconOnLeft && toggleButton != null) ...[
              if (title != null) const SizedBox(width: spacing),
              toggleButton,
            ],
          ],
        );
      },
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
      clipBehavior: clipContent ? Clip.hardEdge : Clip.none,
      child: buildPanelLayout(context, header, child),
    );
  }
}
