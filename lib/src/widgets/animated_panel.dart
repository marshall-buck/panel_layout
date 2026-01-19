import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import '../models/panel_enums.dart';
import '../state/panel_runtime_state.dart';
import '../theme/panel_theme.dart';
import '../constants.dart';
import 'base_panel.dart';
import 'inline_panel.dart';
import 'panel_toggle_button.dart';

/// An internal wrapper that handles animations for a panel's size and visibility.
///
/// This widget is responsible for:
/// 1. Interpolating the size of the panel based on [factor] (visibility) and [collapseFactor] (rail).
/// 2. Managing the opacity cross-fade between the full panel content and the collapsed rail.
/// 3. Clipping the content during transitions.
@internal
class AnimatedPanel extends StatelessWidget {
  const AnimatedPanel({
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

    final theme = PanelTheme.of(context);
    final base = state.size;

    double collapsed = 0.0;
    double? iconSize;

    if (config is InlinePanel) {
      iconSize = config.iconSize ?? theme.iconSize;
      collapsed = iconSize + kDefaultRailPadding;
    }

    final currentSize = base + (collapsed - base) * collapseFactor;
    final animatedSize = currentSize * factor;

    final bool hasFixedWidth = config.width != null;
    final bool hasFixedHeight = config.height != null;

    final expandedSize = state.size;
    final stripSize = collapsed;

    // Use icon to build the strip widget
    Widget? stripWidget;
    final effectiveIcon = config.icon;

    if (effectiveIcon != null && config is InlinePanel) {
      final inline = config as InlinePanel;
      stripWidget = PanelToggleButton(
        icon: effectiveIcon,
        panelId: config.id,
        size: iconSize ?? theme.iconSize,
        color: config.iconColor ?? theme.iconColor,
        closingDirection: inline.closingDirection,
        shouldRotate: inline.rotateIcon,
      );

      // Fix Vertical Alignment:
      // If the rail is vertical (Left/Right anchor), the icon sits at the top.
      // We need to center it vertically within the 'headerHeight' to match the
      // position it had in the expanded header.
      if (config.anchor == PanelAnchor.left ||
          config.anchor == PanelAnchor.right) {
        stripWidget = SizedBox(
          height: theme.headerHeight,
          child: Center(child: stripWidget),
        );
      }
    }

    // Opacity for the Expanded Content
    final contentOpacity = (factor * (1.0 - collapseFactor)).clamp(0.0, 1.0);

    Widget childWidget = Opacity(
      opacity: contentOpacity,
      child: IgnorePointer(ignoring: contentOpacity == 0.0, child: config),
    );

    // If fixed size, we use SingleChildScrollView to allow content to maintain its
    // intended size during animation (preventing squashing) while avoiding
    // infinite size errors and layout overflow warnings.
    // OverflowBox is used only when both dimensions are fixed, as it is safe then.
    if (hasFixedWidth && hasFixedHeight) {
      childWidget = OverflowBox(
        minWidth: expandedSize,
        maxWidth: expandedSize,
        minHeight: expandedSize,
        maxHeight: expandedSize,
        alignment: _getAlignment(config.anchor),
        child: childWidget,
      );
    } else if (hasFixedWidth) {
      childWidget = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        // Align to end if anchored right
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
      childWidget = SingleChildScrollView(
        scrollDirection: Axis.vertical,
        // Align to end if anchored bottom
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

    Alignment stripAlignment = Alignment.center;
    BoxDecoration? railDecoration;

    if (config is InlinePanel) {
      final inline = config as InlinePanel;
      railDecoration = inline.railDecoration ?? theme.railDecoration;

      // Fallback: If no railDecoration, try to mimic header style
      if (railDecoration == null) {
        if (config.headerDecoration != null) {
           railDecoration = config.headerDecoration;
        } else if (theme.headerDecoration != null) {
           railDecoration = theme.headerDecoration;
        }
      }

      if (inline.railIconAlignment != null) {
        stripAlignment = inline.railIconAlignment!;
      } else {
        switch (config.anchor) {
          case PanelAnchor.top:
          case PanelAnchor.bottom:
            stripAlignment = Alignment.centerRight;
            break;
          case PanelAnchor.left:
          case PanelAnchor.right:
            stripAlignment = Alignment.topCenter;
            break;
        }
      }
    }

    Widget content = Stack(
      alignment: _getAlignment(config.anchor),
      children: [
        childWidget,
        if (stripWidget != null || railDecoration != null)
          Positioned(
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
                    ? stripSize
                    : null,
            height:
                (config.anchor == PanelAnchor.top ||
                        config.anchor == PanelAnchor.bottom)
                    ? stripSize
                    : null,
            child: IgnorePointer(
              ignoring: collapseFactor == 0.0,
              child: Opacity(
                opacity: collapseFactor.clamp(0.0, 1.0),
                child: Container(
                  decoration: railDecoration,
                  alignment: stripAlignment,
                  child: stripWidget,
                ),
              ),
            ),
          ),
      ],
    );

    return SizedBox(
      width: hasFixedWidth ? animatedSize : null,
      height: hasFixedHeight ? animatedSize : null,
      child: ClipRect(child: content),
    );
  }

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
