import 'package:flutter/widgets.dart';
import '../../models/panel_enums.dart';
import '../../models/panel_id.dart';
import '../../widgets/panels/overlay_panel.dart';
import '../layout_data.dart';
import 'layout_context.dart';

class OverlayLayoutStrategy {
  const OverlayLayoutStrategy();

  /// Performs layout for overlay panels.
  ///
  /// [inlineRects] provides the bounds of the already-laid-out inline panels,
  /// used as anchor targets.
  void layout({
    required LayoutContext context,
    required Size size,
    required List<PanelLayoutData> panels,
    required Map<PanelId, Rect> inlineRects,
    required TextDirection textDirection,
  }) {
    // Start with inline rects, but we will add overlay rects as we go
    // so overlays can anchor to previous overlays (if order permits).
    final panelRects = Map<PanelId, Rect>.from(inlineRects);

    final overlayPanels = panels
        .where((p) => p.config is OverlayPanel)
        .toList();

    for (final p in overlayPanels) {
      if (!context.hasChild(p.config.id)) continue;
      final config = p.config as OverlayPanel;

      // Ensure we layout if it's visible OR if it's still animating out (visualFactor > 0)
      if (!p.state.visible && p.visualFactor <= 0) {
        context.layoutChild(
          config.id,
          const BoxConstraints.tightFor(width: 0, height: 0),
        );
        context.positionChild(config.id, Offset.zero);
        continue;
      }

      // Determine Anchor Rect
      Rect anchorRect;
      if (config.anchorTo != null && panelRects.containsKey(config.anchorTo)) {
        anchorRect = panelRects[config.anchorTo]!;
      } else {
        anchorRect = Offset.zero & size;
      }

      // External Anchor (LayerLink) special case
      if (config.anchorLink != null) {
        context.layoutChild(config.id, BoxConstraints.loose(size));
        context.positionChild(config.id, Offset.zero);
        continue;
      }

      // Measure Overlay
      final crossAlign =
          config.crossAxisAlignment ?? CrossAxisAlignment.stretch;
      BoxConstraints childConstraints;

      final isFixed = config.width != null || config.height != null;
      if (isFixed) {
        childConstraints = BoxConstraints.tightFor(
          width: p.animatedWidth,
          height: p.animatedHeight,
        );
      } else {
        childConstraints = BoxConstraints.loose(size);
      }

      if (config.anchorTo != null && panelRects.containsKey(config.anchorTo)) {
        final anchorRect = panelRects[config.anchorTo]!;
        if (crossAlign == CrossAxisAlignment.stretch) {
          if (config.anchor != null) {
            switch (config.anchor!) {
              case PanelAnchor.left:
              case PanelAnchor.right:
                childConstraints = BoxConstraints(
                  minHeight: anchorRect.height,
                  maxHeight: anchorRect.height,
                  minWidth: 0,
                  maxWidth: size.width,
                );
                break;
              case PanelAnchor.top:
              case PanelAnchor.bottom:
                childConstraints = BoxConstraints(
                  minWidth: anchorRect.width,
                  maxWidth: anchorRect.width,
                  minHeight: 0,
                  maxHeight: size.height,
                );
                break;
            }
          }
        }
      }

      // Measure Overlay
      final childSize = context.layoutChild(config.id, childConstraints);

      // Calculate Position
      Offset position;
      final alignment = (config.alignment ?? _defaultAlignment(config.anchor))
          .resolve(textDirection);

      if (config.anchorTo != null) {
        // Relative Positioning
        double dx = 0;
        double dy = 0;
        if (config.anchor != null) {
          switch (config.anchor!) {
            case PanelAnchor.left:
              dx = anchorRect.left - childSize.width;
              dy = _alignAxis(
                anchorRect.top,
                anchorRect.height,
                childSize.height,
                alignment.y,
              );
            case PanelAnchor.right:
              dx = anchorRect.right;
              dy = _alignAxis(
                anchorRect.top,
                anchorRect.height,
                childSize.height,
                alignment.y,
              );
            case PanelAnchor.top:
              dy = anchorRect.top - childSize.height;
              dx = _alignAxis(
                anchorRect.left,
                anchorRect.width,
                childSize.width,
                alignment.x,
              );
            case PanelAnchor.bottom:
              dy = anchorRect.bottom;
              dx = _alignAxis(
                anchorRect.left,
                anchorRect.width,
                childSize.width,
                alignment.x,
              );
          }
        }
        position = Offset(dx, dy);
      } else {
        // Global Positioning
        final rect = alignment.inscribe(childSize, anchorRect);
        position = rect.topLeft;
      }

      context.positionChild(config.id, position);
      panelRects[config.id] = position & childSize;
    }
  }

  Alignment _defaultAlignment(PanelAnchor? anchor) {
    if (anchor == null) return Alignment.center;
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

  double _alignAxis(
    double start,
    double length,
    double childLength,
    double alignPct,
  ) {
    final t = (alignPct + 1.0) / 2.0;
    return start + (length - childLength) * t;
  }
}
