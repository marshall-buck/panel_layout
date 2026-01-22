import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import '../models/panel_enums.dart';
import '../state/panel_runtime_state.dart';
import '../layout/panel_layout_config.dart';
import 'base_panel.dart';
import 'inline_panel.dart';
import 'panel_toggle_button.dart';

/// A specialized animator for "Horizontal" panels (Left/Right anchored).
///
/// **Note:** "Horizontal" here refers to the *direction of the animation* (width changes),
/// not necessarily the aspect ratio of the panel.
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
    required this.factor,
    required this.collapseFactor,
  });

  final BasePanel config;
  final PanelRuntimeState state;
  final double factor;
  final double collapseFactor;

  @override
  Widget build(BuildContext context) {
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

    Widget childWidget = Opacity(
      opacity: contentOpacity,
      child: IgnorePointer(
        ignoring: contentOpacity == 0.0,
        child: config,
      ),
    );

    // Layout Safety for Fixed Sizes:
    if (hasFixedWidth) {
      // Fixed Width: Scroll horizontally to prevent overflow during shrink.
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
    } else {
        // If not fixed width, we still might need to handle the content squeezing.
        // But for now we trust the content acts responsively or the user set a min width logic elsewhere.
        // Actually, to match previous behavior for safety, if it's shrinking, we might want to clip.
    }
    
    // Add OverflowBox logic if height is also fixed (generic fallback from original code)
    // although for "HorizontalPanel" we mostly care about width. 
    // If the panel has fixed height, that constraint comes from the parent or config.
    if (config.height != null && hasFixedWidth) {
         childWidget = OverflowBox(
            minWidth: expandedSize,
            maxWidth: expandedSize,
            minHeight: config.height,
            maxHeight: config.height,
            alignment: _getAlignment(config.anchor),
            child: config, // Need to re-wrap raw config? No, childWidget is already wrapped in Opacity/IgnorePointer.
            // Wait, previous code wrapped childWidget in OverflowBox.
         );
         // Re-applying the Opacity wrapper logic properly:
         childWidget = OverflowBox(
            minWidth: expandedSize,
            maxWidth: expandedSize,
            minHeight: config.height,
            maxHeight: config.height,
            alignment: _getAlignment(config.anchor),
            child: Opacity(
                opacity: contentOpacity,
                child: IgnorePointer(ignoring: contentOpacity == 0.0, child: config),
            ),
         );
    }


    // --- 4. Assemble the Stack ---

    Widget content = Stack(
      alignment: _getAlignment(config.anchor),
      children: [
        childWidget,
        // Only render the rail layer if we have content or decoration for it
        if (railContent != null || railDecoration != null)
          Positioned(
            left: config.anchor == PanelAnchor.left ? 0 : null,
            right: config.anchor == PanelAnchor.right ? 0 : null,
            top: 0,
            bottom: 0,
            width: railSize,
            child: IgnorePointer(
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

    return SizedBox(
      width: hasFixedWidth ? animatedSize : null,
      height: config.height, // Pass through fixed height if any, else null (flexible)
      child: ClipRect(child: content),
    );
  }

  Widget? _buildRailContent(
    BuildContext context,
    PanelLayoutConfig config,
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

  BoxDecoration? _getRailDecoration(PanelLayoutConfig config) {
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
