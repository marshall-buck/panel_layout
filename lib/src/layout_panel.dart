import 'dart:ui';
import 'package:flutter/material.dart';

import 'panel_controller.dart';
import 'panel_data.dart';
import 'panel_theme.dart';

/// A presentational widget that renders a single panel based on its [PanelController] state.
class LayoutPanel extends StatelessWidget {
  /// Creates a [LayoutPanel].
  const LayoutPanel({
    required this.controller,
    required this.child,
    this.headerBuilder,
    super.key,
  });

  /// The controller that manages the panel's state.
  final PanelController controller;

  /// The main content of the panel.
  final Widget child;

  /// Optional builder for the panel's header.
  final Widget Function(BuildContext context, PanelController controller)? headerBuilder;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final visuals = controller.visuals;
        final isCollapsed = controller.isCollapsed;
        final theme = PanelTheme.of(context);

        // Determine size based on strategy
        final effectiveSize = controller.effectiveSize;
        final isVertical = controller.anchor == PanelAnchor.left || controller.anchor == PanelAnchor.right;

        // Build the panel decoration and content
        Widget panelContent = Container(
          padding: visuals.padding ?? EdgeInsets.zero,
          decoration: BoxDecoration(
            color: visuals.useAcrylic
                ? theme.backgroundColor.withValues(alpha: visuals.tintAlpha ?? 0.8)
                : theme.backgroundColor,
            border: visuals.showBorders ? Border.all(color: theme.borderColor) : null,
            borderRadius: visuals.borderRadius,
            boxShadow: visuals.elevation > 0
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: visuals.elevation,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (headerBuilder != null) headerBuilder!(context, controller),
              if (!isCollapsed) Expanded(child: child),
            ],
          ),
        );

        // Apply Acrylic blur if requested
        if (visuals.useAcrylic) {
          panelContent = ClipRRect(
            borderRadius: visuals.borderRadius ?? BorderRadius.zero,
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: visuals.blurAmount ?? 10.0,
                sigmaY: visuals.blurAmount ?? 10.0,
              ),
              child: panelContent,
            ),
          );
        }

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
              child: isVertical
                  ? SizedBox(width: effectiveSize, child: panelContent)
                  : SizedBox(height: effectiveSize, child: panelContent),
            ),
          );
        } else if (controller.sizing is ContentSizing) {
          final animatedContent = AnimatedSize(
            duration: visuals.animationDuration,
            curve: visuals.animationCurve,
            child: controller.isVisible ? panelContent : const SizedBox.shrink(),
          );

          animatedPanel = isVertical
              ? IntrinsicWidth(child: animatedContent)
              : IntrinsicHeight(child: animatedContent);
        } else {
          // For FlexibleSizing, we return the content directly.
          animatedPanel = controller.isVisible ? panelContent : const SizedBox.shrink();
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