import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import '../models/panel_id.dart';
import '../models/panel_enums.dart';
import '../state/panel_scope.dart';
import '../state/panel_data_scope.dart';

/// A button that toggles the collapsed state of a panel.
///
/// It strictly expects a left-pointing chevron icon and automatically rotates
/// it based on the [direction] or the panel's anchor.
class PanelToggleButton extends StatelessWidget {
  const PanelToggleButton({
    required this.icon,
    this.panelId,
    this.size = 24.0,
    this.decoration,
    this.direction,
    super.key,
  });

  /// The icon to display. This should be a left-pointing chevron.
  /// The widget will rotate it automatically.
  final Widget icon;

  /// The ID of the panel to toggle. If null, uses the nearest enclosing panel.
  final PanelId? panelId;

  /// The size of the button tap area.
  final double size;

  /// Optional decoration (background color, border, etc.) for the button.
  final Decoration? decoration;

  /// The direction the panel opens (expands).
  /// If provided, this overrides the automatic direction inference from the panel anchor.
  final PanelAnimationDirection? direction;

  @override
  Widget build(BuildContext context) {
    final scope = PanelDataScope.maybeOf(context);
    final controller = PanelScope.of(context);

    PanelAnchor anchor = PanelAnchor.left;
    bool isCollapsed = false;

    if (panelId != null) {
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

    PanelAnimationDirection effectiveDirection;

    if (direction != null) {
      effectiveDirection = direction!;
    } else {
      switch (anchor) {
        case PanelAnchor.left:
          effectiveDirection = PanelAnimationDirection.opensRight;
          break;
        case PanelAnchor.right:
          effectiveDirection = PanelAnimationDirection.opensLeft;
          break;
        case PanelAnchor.top:
          effectiveDirection = PanelAnimationDirection.opensDown;
          break;
        case PanelAnchor.bottom:
          effectiveDirection = PanelAnimationDirection.opensUp;
          break;
      }
    }

    double rotation = 0.0;

    switch (effectiveDirection) {
      case PanelAnimationDirection.opensRight:
        rotation = isCollapsed ? math.pi : 0.0;
        break;
      case PanelAnimationDirection.opensLeft:
        rotation = isCollapsed ? 0.0 : math.pi;
        break;
      case PanelAnimationDirection.opensDown:
        rotation = isCollapsed ? math.pi / 2 : -math.pi / 2;
        break;
      case PanelAnimationDirection.opensUp:
        rotation = isCollapsed ? -math.pi / 2 : math.pi / 2;
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
      child: Container(
        width: size,
        height: size,
        decoration: decoration,
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: rotation),
            duration: const Duration(milliseconds: 200),
            builder: (context, angle, child) {
              return Transform.rotate(angle: angle, child: child);
            },
            child: icon,
          ),
        ),
      ),
    );
  }
}
