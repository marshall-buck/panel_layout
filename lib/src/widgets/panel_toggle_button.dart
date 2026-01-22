import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import '../models/panel_id.dart';
import '../models/panel_enums.dart';
import '../state/panel_scope.dart';
import '../state/panel_data_scope.dart';
import '../layout/panel_layout_config.dart';

import 'package:meta/meta.dart';

/// A private button that toggles the collapsed state of a panel.
///
/// It strictly expects a **Left-Pointing Chevron** icon (e.g., `Icons.chevron_left`)
/// and automatically rotates it based on the [closingDirection] or the panel's anchor.
///
/// This component is used internally by [BasePanel] headers and by [AnimatedPanel]
/// in the collapsed rail strip.
@internal
class PanelToggleButton extends StatelessWidget {
  const PanelToggleButton({
    required this.icon,
    this.panelId,
    this.size = 24.0,
    this.closingDirection,
    this.shouldRotate = true,
    this.onTap,
    this.color,
    super.key,
  });

  /// The icon to display. This should be a left-pointing chevron.
  /// The widget will rotate it automatically.
  final Widget icon;

  /// The ID of the panel to toggle. If null, uses the nearest enclosing panel.
  final PanelId? panelId;

  /// The size of the button tap area.
  final double size;

  /// The direction the panel closes towards.
  /// If provided, this overrides the automatic inference from the panel anchor.
  final PanelAnchor? closingDirection;

  /// Whether to automatically rotate the icon based on the panel's state.
  final bool shouldRotate;

  /// Optional override for the tap action.
  /// If null, defaults to toggling the panel collapse state.
  final VoidCallback? onTap;

  /// Optional override for the icon color.
  /// If null, uses the theme's headerIconColor.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scope = PanelDataScope.maybeOf(context);
    final controller = PanelScope.of(context);
    final config = PanelConfigurationScope.of(context);

    // Use the explicitly provided size.
    // The caller is responsible for passing the correct size (e.g. toggleIconSize for rail, headerIconSize for header).
    final double effectiveSize = size;

    PanelAnchor? anchor = PanelAnchor.left;
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

    // Direction logic:
    // If explicit closingDirection provided, use it.
    // Else, anchor determines closing direction (e.g. Left panel closes to Left).
    final PanelAnchor? effectiveClosingDir = closingDirection ?? anchor;

    // Input: Left Chevron (<)
    // 0 deg = Pointing Left.

    double rotation = 0.0;

    if (shouldRotate && effectiveClosingDir != null) {
      switch (effectiveClosingDir) {
        case PanelAnchor.left:
          // Closes Left (<). Opens Right (>).
          // Open (Visible): Point Left (<) to close. (0 deg)
          // Collapsed: Point Right (>) to open. (180 deg)
          rotation = isCollapsed ? math.pi : 0.0;
          break;
        case PanelAnchor.right:
          // Closes Right (>). Opens Left (<).
          // Open: Point Right (>) to close. (180 deg)
          // Collapsed: Point Left (<) to open. (0 deg)
          rotation = isCollapsed ? 0.0 : math.pi;
          break;
        case PanelAnchor.top:
          // Closes Up (^). Opens Down (v).
          // Open: Point Up (^) to close. (90 deg CW from Left <)
          // Collapsed: Point Down (v) to open. (-90 deg CW from Left <)
          rotation = isCollapsed ? -math.pi / 2 : math.pi / 2;
          break;
        case PanelAnchor.bottom:
          // Closes Down (v). Opens Up (^).
          // Open: Point Down (v) to close. (-90 deg CW from Left <)
          // Collapsed: Point Up (^) to open. (90 deg CW from Left <)
          rotation = isCollapsed ? math.pi / 2 : -math.pi / 2;
          break;
      }
    }

    return GestureDetector(
      onTap: onTap ??
          () {
            final targetId = panelId ?? scope?.config.id;
            if (targetId != null) {
              controller.toggleCollapsed(targetId);
            }
          },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: effectiveSize,
        height: effectiveSize,
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(end: rotation),
            duration: const Duration(milliseconds: 200),
            builder: (context, angle, child) {
              return Transform.rotate(angle: angle, child: child);
            },
            child: IconTheme(
              data: IconThemeData(
                size: effectiveSize, // Use passed size
                color: color ?? config.iconColor,
              ),
              child: icon,
            ),
          ),
        ),
      ),
    );
  }
}
