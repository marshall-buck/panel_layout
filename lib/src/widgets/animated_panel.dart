import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import '../models/panel_enums.dart';
import '../state/panel_runtime_state.dart';
import '../theme/panel_theme.dart';
import 'base_panel.dart';
import 'inline_panel.dart';
import 'panel_toggle_button.dart';

/// An internal widget that handles the complex animations for a panel's lifecycle.
///
/// This includes:
/// 1. **Size Animation**: Interpolating the panel's width/height based on its
///    visibility ([factor]) and its collapse state ([collapseFactor]).
/// 2. **Content Transitions**: Managing the cross-fade opacity between the
///    main panel content and the "Rail" (mini-variant) content.
/// 3. **Layout Stability**: Ensuring fixed-size content doesn't break layout
///    constraints during animation by using scroll views or overflow boxes.
///
/// This widget is the visual workhorse for [PanelLayout], effectively translating
/// abstract state into the concrete animated widget tree.
@internal
class AnimatedPanel extends StatelessWidget {
  const AnimatedPanel({
    super.key,
    required this.config,
    required this.state,
    required this.factor,
    required this.collapseFactor,
  });

  /// The static configuration for this panel (id, min/max sizes, initial state).
  final BasePanel config;

  /// The dynamic runtime state (current size, visibility status).
  final PanelRuntimeState state;

  /// The visibility animation factor, ranging from 0.0 (hidden) to 1.0 (fully visible).
  ///
  /// Driven by the [PanelController]'s visibility animation.
  final double factor;

  /// The collapse animation factor, ranging from 0.0 (fully expanded) to 1.0 (fully collapsed/rail).
  ///
  /// Driven by the [PanelController]'s collapse animation.
  final double collapseFactor;

  @override
  Widget build(BuildContext context) {
    // Optimization: Don't build anything if the panel is fully hidden.
    if (factor <= 0 && !state.visible) {
      return const SizedBox.shrink();
    }

    final theme = PanelTheme.of(context);
    final fullSize = state.size;

    // --- 1. Calculate Target Sizes ---

    double collapsed = 0.0;
    double? iconSize;

    // Determine the size of the "Rail" (collapsed state).
    // Currently only InlinePanels support a rail state.
    if (config is InlinePanel) {
      final inline = config as InlinePanel;
      iconSize = inline.iconSize ?? theme.iconSize;
      collapsed = iconSize + (inline.railPadding ?? theme.railPadding);
    }

    // Interpolate size between Expanded (fullSize) and Collapsed state.
    // collapseFactor 0.0 -> fullSize
    // collapseFactor 1.0 -> collapsed size
    final currentSize = fullSize + (collapsed - fullSize) * collapseFactor;

    // Apply visibility factor.
    // factor 1.0 -> full computed size
    // factor 0.0 -> 0 size (hidden)
    final animatedSize = currentSize * factor;

    final bool hasFixedWidth = config.width != null;
    final bool hasFixedHeight = config.height != null;

    final expandedSize = state.size;
    final railSize = collapsed;

    // --- 2. Build Rail Components ---

    final railContent = _buildRailContent(context, theme, iconSize);
    final railDecoration = _getRailDecoration(theme);
    final railAlignment = _calculateRailAlignment();

    // --- 3. Build Main Content with Transition Logic ---

    // Fade out main content as we collapse (collapseFactor goes 0 -> 1)
    // or as we hide (factor goes 1 -> 0).
    final contentOpacity = (factor * (1.0 - collapseFactor)).clamp(0.0, 1.0);

    Widget childWidget = Opacity(
      opacity: contentOpacity,
      child: IgnorePointer(
        // Disable interactions when content is invisible to prevent accidental clicks
        // on the "ghost" of the expanded panel while in rail mode.
        ignoring: contentOpacity == 0.0,
        child: config,
      ),
    );

    // Layout Safety for Fixed Sizes:
    // If a panel has a fixed width/height (e.g. 300px), animating the container
    // down to 0 or rail size would normally cause a layout overflow error.
    // We wrap the content in ScrollViews or OverflowBoxes to allow the container
    // to shrink without forcing the content to violate its fixed constraints.
    if (hasFixedWidth && hasFixedHeight) {
      // Both fixed: Safe to use OverflowBox to center/align content within the shrinking window.
      childWidget = OverflowBox(
        minWidth: expandedSize,
        maxWidth: expandedSize,
        minHeight: expandedSize,
        maxHeight: expandedSize,
        alignment: _getAlignment(config.anchor),
        child: childWidget,
      );
    } else if (hasFixedWidth) {
      // Fixed Width only: Scroll horizontally.
      childWidget = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        // If anchored right, we want the "end" of the content to stay visible as it clips.
        reverse: config.anchor == PanelAnchor.right,
        physics: const NeverScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: expandedSize,
            maxWidth: expandedSize,
          ),
          child: childWidget,
        ),
      );
    } else if (hasFixedHeight) {
      // Fixed Height only: Scroll vertically.
      childWidget = SingleChildScrollView(
        scrollDirection: Axis.vertical,
        // If anchored bottom, we want the bottom of the content to stay visible.
        reverse: config.anchor == PanelAnchor.bottom,
        physics: const NeverScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: expandedSize,
            maxHeight: expandedSize,
          ),
          child: childWidget,
        ),
      );
    }

    // --- 4. Assemble the Stack ---

    // We stack the Main Content and the Rail Content.
    // They are absolutely positioned relative to the animating container.
    Widget content = Stack(
      alignment: _getAlignment(config.anchor),
      children: [
        childWidget,
        // Only render the rail layer if we have content or decoration for it
        if (railContent != null || railDecoration != null)
          Positioned(
            // Pin the rail to the correct edge based on anchor.
            // For Left/Right anchors, it's a vertical strip (top:0, bottom:0).
            // For Top/Bottom anchors, it's a horizontal strip (left:0, right:0).
            left:
                (config.anchor == PanelAnchor.left ||
                    config.anchor == PanelAnchor.right)
                ? (config.anchor == PanelAnchor.left ? 0 : null)
                : 0,
            right:
                (config.anchor == PanelAnchor.left ||
                    config.anchor == PanelAnchor.right)
                ? (config.anchor == PanelAnchor.right ? 0 : null)
                : 0,
            top:
                (config.anchor == PanelAnchor.top ||
                    config.anchor == PanelAnchor.bottom)
                ? (config.anchor == PanelAnchor.top ? 0 : null)
                : 0,
            bottom:
                (config.anchor == PanelAnchor.top ||
                    config.anchor == PanelAnchor.bottom)
                ? (config.anchor == PanelAnchor.bottom ? 0 : null)
                : 0,
            width:
                (config.anchor == PanelAnchor.left ||
                    config.anchor == PanelAnchor.right)
                ? railSize
                : null,
            height:
                (config.anchor == PanelAnchor.top ||
                    config.anchor == PanelAnchor.bottom)
                ? railSize
                : null,
            child: IgnorePointer(
              // Rail is only interactive when actually collapsed
              ignoring: collapseFactor == 0.0,
              child: Opacity(
                opacity: collapseFactor.clamp(0.0, 1.0),
                child: Container(
                  decoration: railDecoration,
                  alignment: railAlignment,
                  child: railContent,
                ),
              ),
            ),
          ),
      ],
    );

    // Wrap in ClipRect to ensure content doesn't bleed out during size animation
    return SizedBox(
      width: hasFixedWidth ? animatedSize : null,
      height: hasFixedHeight ? animatedSize : null,
      child: ClipRect(child: content),
    );
  }

  /// Builds the content for the collapsed "Rail" state (Mini Variant).
  ///
  /// This typically consists of a [PanelToggleButton] that allows the user to
  /// re-expand the panel.
  ///
  /// **Logic:**
  /// 1. If an icon is present in the config, it builds a toggle button.
  /// 2. For vertical rails (Left/Right anchors), it centers the icon vertically
  ///    within a height matching [PanelTheme.headerHeight] to ensure it aligns
  ///    visually with the header of the expanded panel.
  Widget? _buildRailContent(
    BuildContext context,
    PanelThemeData theme,
    double? iconSize,
  ) {
    if (config is! InlinePanel) return null;
    final effectiveIcon = config.icon;
    if (effectiveIcon == null) return null;

    final inline = config as InlinePanel;
    Widget railContent = PanelToggleButton(
      icon: effectiveIcon,
      panelId: config.id,
      size: iconSize ?? theme.iconSize,
      color: config.iconColor ?? theme.iconColor,
      closingDirection: inline.closingDirection,
      shouldRotate: inline.rotateIcon,
    );

    // Fix Vertical Alignment for Side Anchors:
    // If the panel is on the Left/Right, the rail is a vertical strip.
    // The icon should logically sit at the "top" of this strip, aligned
    // with where the header icon would be in the expanded state.
    if (config.anchor == PanelAnchor.left ||
        config.anchor == PanelAnchor.right) {
      final effectivePadding = config.headerPadding ?? theme.headerPadding;
      final effectiveHeaderHeight = config.headerHeight ??
          ((iconSize ?? theme.iconSize) + (effectivePadding * 2));

      railContent = SizedBox(
        height: effectiveHeaderHeight,
        child: Center(child: railContent),
      );
    }
    return railContent;
  }

  /// Determines the visual decoration for the rail container.
  ///
  /// **Priority Order:**
  /// 1. `InlinePanel.railDecoration`: Specific override for this panel's rail.
  /// 2. `PanelTheme.railDecoration`: Global theme default for rails.
  /// 3. `InlinePanel.headerDecoration`: Fallback to match this panel's header.
  /// 4. `PanelTheme.headerDecoration`: Fallback to match the global header theme.
  ///
  /// This fallback chain ensures that if a user hasn't explicitly styled the
  /// rail, it seamlessly blends with the header, creating a "tab-like" effect.
  BoxDecoration? _getRailDecoration(PanelThemeData theme) {
    if (config is! InlinePanel) return null;
    final inline = config as InlinePanel;

    BoxDecoration? decoration = inline.railDecoration ?? theme.railDecoration;

    // Fallback: If no specific rail decoration is provided, try to match the
    // header decoration to create a seamless visual transition.
    if (decoration == null) {
      if (config.headerDecoration != null) {
        decoration = config.headerDecoration;
      } else if (theme.headerDecoration != null) {
        decoration = theme.headerDecoration;
      }
    }
    return decoration;
  }

  /// Calculates the alignment of content within the rail strip.
  ///
  /// **Logic:**
  /// 1. If `InlinePanel.railIconAlignment` is set, it takes precedence.
  /// 2. Otherwise, applies smart defaults based on the [PanelAnchor]:
  ///    - **Top/Bottom (Horizontal Rail)**: Aligns to `centerRight`.
  ///    - **Left/Right (Vertical Rail)**: Aligns to `topCenter`.
  Alignment _calculateRailAlignment() {
    if (config is! InlinePanel) return Alignment.center;
    final inline = config as InlinePanel;

    if (inline.railIconAlignment != null) {
      return inline.railIconAlignment!;
    }

    // Smart defaults based on anchor position
    switch (config.anchor) {
      case PanelAnchor.top:
      case PanelAnchor.bottom:
        // Horizontal rails: Align to the right
        return Alignment.centerRight;
      case PanelAnchor.left:
      case PanelAnchor.right:
        // Vertical rails: Align to the top
        return Alignment.topCenter;
    }
  }

  /// Maps the abstract [PanelAnchor] to a concrete [Alignment].
  Alignment _getAlignment(PanelAnchor anchor) {
    switch (anchor) {
      case PanelAnchor.left:
        return Alignment.centerLeft;
      case PanelAnchor.right:
        return Alignment.centerRight;
      case PanelAnchor.top:
        return Alignment.topCenter;
      case PanelAnchor.bottom:
        return Alignment.bottomCenter;
    }
  }
}
