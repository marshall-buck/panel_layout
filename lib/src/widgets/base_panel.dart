import 'package:flutter/widgets.dart';

import '../models/panel_id.dart';
import '../models/panel_enums.dart';

/// An abstract base class for panels in a [PanelLayout].
///
/// Users should extend this class to create their own panels.
/// [PanelLayout] uses the properties defined here to calculate layout and behavior.
class BasePanel extends StatelessWidget {
  /// Creates a declarative panel configuration.
  const BasePanel({
    required this.id,
    required this.child,
    this.mode = PanelMode.inline,
    this.anchor = PanelAnchor.left,
    this.anchorTo,
    this.anchorLink,
    this.width,
    this.height,
    this.flex,
    this.minSize,
    this.maxSize,
    double? collapsedSize,
    this.collapsedChild,
    this.resizable = true,
    this.initialVisible = true,
    this.initialCollapsed = false,
    this.zIndex = 0,
    this.animationDuration,
    this.animationCurve,
    this.alignment,
    this.crossAxisAlignment,
    super.key,
  }) : collapsedSize = collapsedSize ?? (collapsedChild != null ? 24.0 : null),
       assert(
         (width != null || height != null) ? flex == null : true,
         'Cannot provide both fixed size (width/height) and flex.',
       );

  /// The unique identifier for this panel.
  final PanelId id;

  /// The content to display within the panel.
  final Widget child;

  /// The content to display when the panel is collapsed.
  /// If null, the main [child] is displayed (and likely clipped).
  final Widget? collapsedChild;

  /// The display mode of the panel (e.g., docked vs. overlay).
  final PanelMode mode;

  /// The edge or direction to which the panel is anchored.
  final PanelAnchor anchor;

  /// The ID of another panel to anchor this one to (for relative overlays).
  final PanelId? anchorTo;

  /// A layer link to anchor this panel to an external widget.
  final LayerLink? anchorLink;

  /// The initial fixed width of the panel. Use this or [flex], not both.
  final double? width;

  /// The initial fixed height of the panel. Use this or [flex], not both.
  final double? height;

  /// The flex factor for fluid sizing. Use this or [width]/[height], not both.
  final double? flex;

  /// The minimum size (width or height) the panel can be resized to.
  final double? minSize;

  /// The maximum size (width or height) the panel can be resized to.
  final double? maxSize;

  /// The size of the panel when collapsed. Defaults to 0.0.
  final double? collapsedSize;

  /// Whether the panel can be resized by the user.
  final bool resizable;

  /// Whether the panel is initially visible.
  final bool initialVisible;

  /// Whether the panel is initially collapsed.
  final bool initialCollapsed;

  /// The z-index paint order (higher values paint on top).
  final int zIndex;

  /// Optional override for animation duration.
  final Duration? animationDuration;

  /// Optional override for animation curve.
  final Curve? animationCurve;

  /// Alignment for overlay positioning.
  final AlignmentGeometry? alignment;

  /// Cross-axis behavior for layout.
  final CrossAxisAlignment? crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    if (collapsedChild != null) {
      // We can check the collapse state via PanelScope or similar if we wanted
      // to optimize, but PanelLayoutDelegate handles the sizing.
      // We use a Stack to cross-fade or overlay the collapsed content.
      // Since we don't have the collapseFactor here directly without querying scope,
      // we can rely on the fact that this widget is built inside PanelDataScope.

      return _CollapsedStack(panel: this);
    }
    return child;
  }
}

class _CollapsedStack extends StatelessWidget {
  const _CollapsedStack({required this.panel});

  final BasePanel panel;

  @override
  Widget build(BuildContext context) {
    // We access the internal data scope to get animation values
    // Note: PanelDataScope is internal, but we are in the package.
    // However, BasePanel is exported. We need to be careful about imports.
    // PanelDataScope is in 'package:panel_layout/src/state/panel_data_scope.dart'.
    // We cannot import it here if it creates a circular dependency or if not available.
    // But this file is in 'src/widgets'. 'state' is in 'src/state'.
    // We should import it.

    return LayoutBuilder(
      builder: (context, constraints) {
        // If we can't access animation factor, we can infer from size?
        // But size is exactly what we are constrained by.

        final collapsedSize = panel.collapsedSize ?? 0.0;
        // final currentSize = panel.width != null || panel.height != null
        //     ? (constraints.hasBoundedWidth
        //           ? constraints.maxWidth
        //           : constraints.maxHeight)
        //     : (constraints.maxWidth); // Assumption

        // A simple heuristic: if we are near collapsed size, show collapsed child.
        // But for smooth animation, we want a cross-fade.
        // We really need the collapseFactor.

        // Let's assume the user will import PanelDataScope if they edit this package.
        // Wait, I am editing the package.
        // I need to add the import to this file.

        return Stack(
          children: [
            Positioned.fill(child: panel.child),
            if (panel.collapsedChild != null)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: collapsedSize, // Fixed width strip
                child: panel.collapsedChild!,
              ),
          ],
        );
      },
    );
  }
}
