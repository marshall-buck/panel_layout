import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import '../models/panel_enums.dart';
import '../state/panel_runtime_state.dart';
import 'base_panel.dart';
import 'inline_panel.dart';
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

    final base = state.size;
    final collapsed =
        config is InlinePanel
            ? (config as InlinePanel).collapsedSize ?? 0.0
            : 0.0;
    final currentSize = base + (collapsed - base) * collapseFactor;

    final animatedSize = currentSize * factor;

    final bool hasFixedWidth = config.width != null;
    final bool hasFixedHeight = config.height != null;

    final expandedSize = state.size;
    final stripSize =
        config is InlinePanel
            ? (config as InlinePanel).collapsedSize ?? 0.0
            : 0.0;

    // Use toggleIcon to build the strip widget
    Widget? stripWidget;
    if (config.toggleIcon != null) {
      stripWidget = PanelToggleButton(
        icon: config.toggleIcon!,
        panelId: config.id,
        closingDirection: config.closingDirection,
      );
    }

    Widget childWidget = Opacity(
      opacity: factor.clamp(0.0, 1.0),
      child: config,
    );

    if (hasFixedWidth || hasFixedHeight) {
      childWidget = OverflowBox(
        alignment: _getAlignment(config.anchor),
        minWidth: hasFixedWidth ? expandedSize : null,
        maxWidth: hasFixedWidth ? expandedSize : null,
        minHeight: hasFixedHeight ? expandedSize : null,
        maxHeight: hasFixedHeight ? expandedSize : null,
        child: childWidget,
      );
    }

    Widget content = Stack(
      alignment: _getAlignment(config.anchor),
      children: [
        childWidget,
        if (stripWidget != null || config.collapsedDecoration != null)
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
                  decoration: config.collapsedDecoration,
                  alignment: Alignment.center,
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
