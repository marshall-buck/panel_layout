import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import '../../models/panel_enums.dart';
import '../../state/panel_runtime_state.dart';
import '../../models/panel_style.dart';
import '../panels/base_panel.dart';
import '../panels/inline_panel.dart';
import '../internal/panel_toggle_button.dart';

/// A specialized animator for "Horizontal" panels (Left/Right anchored).
///
/// This widget acts as a wrapper for panels that visually appear as **Sidebars**
/// or **Vertical Rails**. It is named "Horizontal" because it animates the
/// panel along the **Horizontal Axis** (changing its width).
///
/// This widget handles the complex animations for a side panel's lifecycle:
/// 1. **Size Animation**: Interpolating the panel's width based on its
///    visibility ([factor]) and its collapse state ([collapseFactor]).
/// 2. **Content Transitions**: Managing the cross-fade opacity between the
///    main panel content and the vertical "Rail" (icon strip).
/// 3. **Layout Stability**: Ensuring fixed-size content doesn't break layout
///    constraints during animation by using scroll views or overflow boxes.
@internal
class AnimatedHorizontalPanel extends StatelessWidget {
  const AnimatedHorizontalPanel({
    super.key,
    required this.config,
    required this.state,
    required this.visibilityAnimation,
    required this.collapseAnimation,
  });

  final BasePanel config;
  final PanelRuntimeState state;
  final Animation<double> visibilityAnimation;
  final Animation<double> collapseAnimation;

  @override
  Widget build(BuildContext context) {
    final factor = visibilityAnimation.value;
    final collapseFactor = collapseAnimation.value;

    if (factor <= 0 && !state.visible) {
      return const SizedBox.shrink();
    }

    final layoutConfig = PanelConfigurationScope.of(context);
    final fullSize = state.size;

    // --- 1. Calculate Target Sizes ---

    double collapsed = 0.0;
    double? iconSize;

    // Determine the size of the "Rail" (collapsed state).
    if (config is InlinePanel) {
      final inline = config as InlinePanel;
      iconSize = inline.iconSize ?? layoutConfig.iconSize;

      // Standard Rail (Icon only) for side panels
      collapsed = iconSize + (inline.railPadding ?? layoutConfig.railPadding);
    }

    // Interpolate size between Expanded (fullSize) and Collapsed state.
    final currentSize = fullSize + (collapsed - fullSize) * collapseFactor;

    // Apply visibility factor.
    final animatedSize = currentSize * factor;

    final bool hasFixedWidth = config.width != null;
    final expandedSize = state.size;
    final railSize = collapsed;

    // --- 2. Build Rail Components ---

    final railContent = _buildRailContent(context, layoutConfig, iconSize);
    final railDecoration = _getRailDecoration(layoutConfig);
    final railAlignment = _calculateRailAlignment();

    // --- 3. Build Main Content with Transition Logic ---

    final contentOpacity = (factor * (1.0 - collapseFactor)).clamp(0.0, 1.0);

    // OPTIMIZATION: Wrap content in RepaintBoundary to cache rasterization during animations.
    // This is crucial for performance when animating Opacity of complex children (like Lists).
    Widget childWidget = RepaintBoundary(child: config);
    
    // OPTIMIZATION: Only wrap in Opacity/IgnorePointer if not fully opaque
    if (contentOpacity < 1.0) {
      childWidget = Opacity(
        opacity: contentOpacity,
        child: IgnorePointer(ignoring: contentOpacity == 0.0, child: childWidget),
      );
    }

    // Layout Safety for Fixed Sizes:
    if (hasFixedWidth) {
      // Fixed Width: Scroll horizontally to prevent overflow during shrink.
      // We use SingleChildScrollView because it correctly handles "wrap content height"
      // while allowing "overflow width", avoiding infinite size errors or overflow warnings.
      childWidget = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
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
    }

    // Add OverflowBox logic if height is also fixed
    if (config.height != null && hasFixedWidth) {
      childWidget = OverflowBox(
        minWidth: expandedSize,
        maxWidth: expandedSize,
        minHeight: config.height,
        maxHeight: config.height,
        alignment: _getAlignment(config.anchor),
        child: childWidget,
      );
    }

    // --- 4. Assemble the Stack ---

    Widget content = Stack(
      alignment: _getAlignment(config.anchor),
      children: [
        childWidget,
        // Only render the rail layer if we have content or decoration for it
        if (railContent != null || railDecoration != null)
          _buildRailLayer(
            railSize: railSize,
            collapseFactor: collapseFactor,
            decoration: railDecoration,
            alignment: railAlignment,
            child: railContent,
          ),
      ],
    );

    return SizedBox(
      width: hasFixedWidth ? animatedSize : null,
      height: config
          .height, // Pass through fixed height if any, else null (flexible)
      child: ClipRect(child: content),
    );
  }

  Widget _buildRailLayer({
    required double railSize,
    required double collapseFactor,
    required BoxDecoration? decoration,
    required Alignment alignment,
    required Widget? child,
  }) {
    // Note: We keep the rail in the tree even if collapseFactor is 0 (fully expanded)
    // so that widget finders in tests can locate it (even if invisible).
    // Opacity 0.0 is efficient enough (skips painting).

    Widget rail = Container(
      decoration: decoration,
      alignment: alignment,
      child: child,
    );

    // OPTIMIZATION: Only wrap in Opacity/IgnorePointer if not fully collapsed
    if (collapseFactor < 1.0) {
      rail = Opacity(
        opacity: collapseFactor.clamp(0.0, 1.0),
        child: rail,
      );
    }

    return Positioned(
      left: config.anchor == PanelAnchor.left ? 0 : null,
      right: config.anchor == PanelAnchor.right ? 0 : null,
      top: 0,
      bottom: 0,
      width: railSize,
      child: IgnorePointer(
        ignoring: collapseFactor == 0.0,
        child: rail,
      ),
    );
  }

  Widget? _buildRailContent(
    BuildContext context,
    PanelStyle config,
    double? iconSize,
  ) {
    if (this.config is! InlinePanel) return null;
    final effectiveIcon = this.config.icon;
    if (effectiveIcon == null) return null;

    final inline = this.config as InlinePanel;
    Widget railContent = PanelToggleButton(
      icon: effectiveIcon,
      panelId: this.config.id,
      size: iconSize ?? config.iconSize,
      color: this.config.iconColor ?? config.iconColor,
      closingDirection: inline.closingDirection,
      shouldRotate: inline.rotateIcon,
    );

    // Fix Vertical Alignment for Side Anchors:
    final effectivePadding = this.config.headerPadding ?? config.headerPadding;
    final effectiveHeaderHeight =
        this.config.headerHeight ??
        ((iconSize ?? config.iconSize) + (effectivePadding * 2));

    railContent = SizedBox(
      height: effectiveHeaderHeight,
      child: Center(child: railContent),
    );

    return railContent;
  }

  BoxDecoration? _getRailDecoration(PanelStyle config) {
    if (this.config is! InlinePanel) return null;
    final inline = this.config as InlinePanel;

    BoxDecoration? decoration = inline.railDecoration ?? config.railDecoration;

    if (decoration == null) {
      if (this.config.headerDecoration != null) {
        decoration = this.config.headerDecoration;
      } else if (config.headerDecoration != null) {
        decoration = config.headerDecoration;
      }
    }
    return decoration;
  }

  Alignment _calculateRailAlignment() {
    if (config is! InlinePanel) return Alignment.center;
    final inline = config as InlinePanel;

    if (inline.railIconAlignment != null) {
      return inline.railIconAlignment!;
    }
    // Vertical rails (Left/Right): Align to the top
    return Alignment.topCenter;
  }

  Alignment _getAlignment(PanelAnchor? anchor) {
    if (anchor == PanelAnchor.right) return Alignment.centerRight;
    return Alignment.centerLeft;
  }
}
