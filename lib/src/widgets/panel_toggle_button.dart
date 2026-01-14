import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import '../models/panel_id.dart';
import '../models/panel_enums.dart';
import '../state/panel_scope.dart';
import '../state/panel_data_scope.dart';

/// A button that toggles the collapsed state of a panel.
///
/// It automatically rotates its [child] (icon) based on the panel's
/// anchor and collapse state.
///
/// If [panelId] is not provided, it attempts to find the closest [PanelDataScope].
class PanelToggleButton extends StatelessWidget {
  const PanelToggleButton({
    required this.child,
    this.panelId,
    this.size = 24.0,
    super.key,
  });

  /// The icon to display (usually a chevron pointing LEFT).
  final Widget child;

  /// The ID of the panel to toggle. If null, uses the nearest enclosing panel.
  final PanelId? panelId;

  /// The size of the button tap area.
  final double size;

  @override
  Widget build(BuildContext context) {
    final scope = PanelDataScope.maybeOf(context);
    final controller = PanelScope.of(context);

    // If panelId is explicit, we can't easily get its config (Anchor)
    // without looking it up in the LayoutController or State.
    // But LayoutController doesn't expose configs publicly.
    // So this widget works best when placed INSIDE the panel (scope != null).

    // If external, we assume standard behavior or no rotation if we can't find anchor.
    // However, the requirement is "package should figure out the way...".

    PanelAnchor anchor = PanelAnchor.left;
    bool isCollapsed = false;

    if (panelId != null) {
      // External control. We don't know the anchor easily unless we query the layout logic.
      // But PanelLayout doesn't expose a "getPanelConfig(id)" API.
      // We'll have to rely on the user to put it inside, or add that API.
      // For now, if explicit ID, we just toggle. Rotation might be static.
      // BUT, if scope matches ID, use scope.
      if (scope != null && scope.config.id == panelId) {
        anchor = scope.config.anchor;
        isCollapsed = scope.state.collapsed;
      }
    } else {
      if (scope != null) {
        anchor = scope.config.anchor;
        isCollapsed = scope.state.collapsed;
      }
    }

    // Determine rotation
    // User supplies LEFT pointing chevron.
    // Anchor Left:
    //   Open: Points Left (Standard). Rotation 0.
    //   Collapsed: Points Right (to open). Rotation 180 (pi).
    // Anchor Right:
    //   Open: Points Right (to close). Rotation 180.
    //   Collapsed: Points Left (to open). Rotation 0.

    double rotation = 0.0;

    switch (anchor) {
      case PanelAnchor.left:
        rotation = isCollapsed ? math.pi : 0.0;
        break;
      case PanelAnchor.right:
        rotation = isCollapsed ? 0.0 : math.pi;
        break;
      case PanelAnchor.top:
        // Left Chevron points Left.
        // Top Panel Open: Point Up? (90 deg). Collapsed: Point Down?
        // This assumes user provides LEFT chevron.
        // Let's assume standard behavior:
        // Open: Arrow points into panel (Up).
        // Closed: Arrow points out (Down).
        rotation = isCollapsed ? -math.pi / 2 : math.pi / 2;
        break;
      case PanelAnchor.bottom:
        rotation = isCollapsed ? math.pi / 2 : -math.pi / 2;
        break;
    }

    return GestureDetector(
      onTap: () {
        final targetId = panelId ?? scope?.config.id;
        if (targetId != null) {
          controller.toggleCollapsed(targetId);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: rotation),
            duration: const Duration(milliseconds: 200),
            builder: (context, angle, child) {
              return Transform.rotate(angle: angle, child: child);
            },
            child: child,
          ),
        ),
      ),
    );
  }
}
