import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import '../models/panel_enums.dart';
import '../state/panel_runtime_state.dart';
import 'base_panel.dart';
import 'panel_toggle_button.dart';

/// An internal wrapper that handles animations for a panel's size and visibility.
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

    // Target size (outer container)
    // We want smooth interpolation for the box size, which PanelLayoutDelegate handles.
    // BUT here, 'state.collapsed' is a boolean.
    // We need to use 'collapseFactor' to interpolate the targetSize if we want strictly correct sizing?
    // Actually, PanelLayoutDelegate uses 'PanelLayoutData.effectiveSize' which DOES interpolate.
    // So the delegate gives us a specific constraint.
    // But AnimatedPanel returns a SizedBox of a specific size.
    // It should match effectiveSize.

    // effectiveSize = base + (collapsed - base) * collapseFactor
    final base = state.size;
    final collapsed = config.collapsedSize ?? 0.0;
    final currentSize = base + (collapsed - base) * collapseFactor;

    // Applying visualFactor (visibility)
    final animatedSize = currentSize * factor;

    final bool hasFixedWidth = config.width != null;
    final bool hasFixedHeight = config.height != null;

    final expandedSize = state.size;
    final stripSize = config.collapsedSize ?? 0.0;

    // If we have a toggle icon or custom strip, we build it.
    Widget? stripWidget;
    if (config.collapsedChild != null) {
      stripWidget = config.collapsedChild;
    } else if (config.toggleIcon != null) {
      stripWidget = Container(
        // Default styling matches generic sidebar/toolbar
        alignment: Alignment.center,
        child: PanelToggleButton(child: config.toggleIcon!),
      );
    }

    Widget content = Stack(
      children: [
        // 1. The Main Content
        Positioned.fill(
          child: OverflowBox(
            alignment: _getAlignment(config.anchor),
            minWidth: hasFixedWidth ? expandedSize : null,
            maxWidth: hasFixedWidth ? expandedSize : null,
            minHeight: hasFixedHeight ? expandedSize : null,
            maxHeight: hasFixedHeight ? expandedSize : null,
            child: Opacity(
              // Fade out as we collapse?
              // Usually content stays visible, just slides.
              // But if we want to cross-fade to the strip...
              // Let's keep content fully opaque for now, or fade it out if it overlaps strip?
              // If Side-by-Side: Content opacity should be 1.0.
              // If Strip is Overlay: Content opacity 1.0.
              opacity: factor.clamp(0.0, 1.0),
              child: config, // The User's Widget
            ),
          ),
        ),

        // 2. The Strip
        if (stripWidget != null)
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
                // Fade in the strip as we collapse.
                // collapseFactor: 0.0 (Expanded) -> 1.0 (Collapsed)
                opacity: collapseFactor.clamp(0.0, 1.0),
                child: stripWidget,
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
        // If we anchor Left, the panel grows from Left.
        // If we collapse to 48px, we see the left-most 48px.
        return Alignment.centerLeft;

      case PanelAnchor.right:
        // Anchor Right. Panel grows from Right.
        // Collapsed: see right-most 48px.
        return Alignment.centerRight;

      case PanelAnchor.top:
        return Alignment.topCenter;

      case PanelAnchor.bottom:
        return Alignment.bottomCenter;
    }
  }
}
