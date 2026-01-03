import 'package:flutter/widgets.dart';

import 'panel_controller.dart';
import 'panel_data.dart';
import 'panel_theme.dart';

/// A presentational widget that renders a single panel based on its [PanelController] state.
///
/// This widget handles:
/// - Visibility (via [PanelController.isVisible])
/// - Sizing Animation (Fixed/Content)
/// - Overlay Transitions
/// - Optional Visual Styling (via [PanelThemeData.panelDecoration] and [PanelThemeData.panelPadding])
///
/// The [child] widget is responsible for rendering the panel's main content.
class LayoutPanel extends StatelessWidget {
  /// Creates a [LayoutPanel].
  const LayoutPanel({
    required this.controller,
    required this.child,
    super.key,
  });

  /// The controller that manages the panel's state.
  final PanelController controller;

  /// The content of the panel.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final theme = PanelTheme.of(context);
        final visuals = controller.visuals;
        final isCollapsed = controller.isCollapsed;

        // Apply theme decoration and padding
        final decoratedChild = Container(
          decoration: theme.panelDecoration,
          padding: theme.panelPadding,
          child: child,
        );

        // Determine size based on strategy
        final effectiveSize = controller.effectiveSize;
        final isVertical = controller.anchor == PanelAnchor.left || controller.anchor == PanelAnchor.right;

        Widget animatedPanel;

        // Apply sizing and animations
        if (controller.sizing is FixedSizing || isCollapsed) {
          animatedPanel = AnimatedContainer(
            duration: visuals.animationDuration,
            curve: visuals.animationCurve,
            width: isVertical ? effectiveSize : null,
            height: isVertical ? null : effectiveSize,
            child: SingleChildScrollView(
              scrollDirection: isVertical ? Axis.horizontal : Axis.vertical,
              physics: const NeverScrollableScrollPhysics(), // Disable scrolling by user, it's just for clipping/layout
              child: isVertical
                  ? SizedBox(width: effectiveSize, child: decoratedChild)
                  : SizedBox(height: effectiveSize, child: decoratedChild),
            ),
          );
        } else if (controller.sizing is ContentSizing) {
          final animatedContent = AnimatedSize(
            duration: visuals.animationDuration,
            curve: visuals.animationCurve,
            child: controller.isVisible ? decoratedChild : const SizedBox.shrink(),
          );

          animatedPanel = isVertical
              ? IntrinsicWidth(child: animatedContent)
              : IntrinsicHeight(child: animatedContent);
        } else {
          // For FlexibleSizing, we return the content directly.
          animatedPanel = controller.isVisible ? decoratedChild : const SizedBox.shrink();
        }

        // For Overlay panels, we add a Slide transition
        if (controller.mode == PanelMode.overlay) {
          return AnimatedSwitcher(
            duration: visuals.animationDuration,
            switchInCurve: visuals.animationCurve,
            switchOutCurve: visuals.animationCurve,
            transitionBuilder: (child, animation) {
              Offset begin;
              switch (controller.anchor) {
                case PanelAnchor.right:
                  begin = const Offset(1, 0);
                case PanelAnchor.left:
                  begin = const Offset(-1, 0);
                case PanelAnchor.top:
                  begin = const Offset(0, -1);
                case PanelAnchor.bottom:
                  begin = const Offset(0, 1);
              }

              return SlideTransition(
                position: Tween<Offset>(
                  begin: begin,
                  end: Offset.zero,
                ).animate(animation),
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            child: controller.isVisible
                ? KeyedSubtree(
                    key: ValueKey('panel_${controller.id.value}_visible'),
                    child: animatedPanel,
                  )
                : SizedBox.shrink(
                    key: ValueKey('panel_${controller.id.value}_hidden'),
                  ),
          );
        }

        return animatedPanel;
      },
    );
  }
}