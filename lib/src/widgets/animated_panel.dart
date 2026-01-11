import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import '../models/panel_enums.dart';
import '../state/panel_runtime_state.dart';
import 'base_panel.dart';

/// An internal wrapper that handles animations for a panel's size and visibility.
@internal
class AnimatedPanel extends StatelessWidget {
  const AnimatedPanel({
    super.key,
    required this.config,
    required this.state,
    required this.factor,
  });

  final BasePanel config;
  final PanelRuntimeState state;
  final double factor;

  @override
  Widget build(BuildContext context) {
    if (factor <= 0 && !state.visible) {
      return const SizedBox.shrink();
    }

    final targetSize = state.collapsed ? (config.collapsedSize ?? 0.0) : state.size;
    
    final bool hasFixedWidth = config.width != null;
    final bool hasFixedHeight = config.height != null;

    // We wrap the content in a SizedBox of the TARGET size.
    Widget content = SizedBox(
      width: hasFixedWidth ? targetSize : null,
      height: hasFixedHeight ? targetSize : null,
      child: Opacity(
        opacity: factor.clamp(0.0, 1.0),
        child: config,
      ),
    );

    // If the axis is fixed, we use OverflowBox to prevent squashing during clipping animations.
    if (hasFixedWidth || hasFixedHeight) {
      content = OverflowBox(
        alignment: _getAlignment(),
        minWidth: hasFixedWidth ? targetSize : null,
        maxWidth: hasFixedWidth ? targetSize : null,
        minHeight: hasFixedHeight ? targetSize : null,
        maxHeight: hasFixedHeight ? targetSize : null,
        child: content,
      );
    }

    // Crucially, we wrap the whole thing in a SizedBox of the ANIMATED size.
    // This ensures the widget tree reflects the size the Delegate intended.
    return SizedBox(
      width: hasFixedWidth ? (targetSize * factor) : null,
      height: hasFixedHeight ? (targetSize * factor) : null,
      child: ClipRect(
        child: content,
      ),
    );
  }

  Alignment _getAlignment() {
    switch (config.anchor) {
      case PanelAnchor.left: return Alignment.centerLeft;
      case PanelAnchor.right: return Alignment.centerRight;
      case PanelAnchor.top: return Alignment.topCenter;
      case PanelAnchor.bottom: return Alignment.bottomCenter;
    }
  }
}
