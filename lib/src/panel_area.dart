import 'package:flutter/material.dart';

import 'layout_controller.dart';
import 'layout_panel.dart';
import 'panel_controller.dart';
import 'panel_data.dart';
import 'panel_resize_handle.dart';

/// A smart container that orchestrates the layout of a group of panels.
class PanelArea extends StatelessWidget {
  /// Creates a [PanelArea].
  const PanelArea({
    required this.controller,
    required this.panelIds,
    required this.panelBuilder,
    this.headerBuilder,
    this.axis = Axis.horizontal,
    super.key,
  });

  /// The layout controller managing the panels.
  final LayoutController controller;

  /// The list of panel IDs to include in this area.
  final List<PanelId> panelIds;

  /// Builder to provide the widget content for a panel.
  final Widget Function(BuildContext context, PanelId id) panelBuilder;

  /// Optional builder for panel headers.
  final Widget Function(BuildContext context, PanelId id, PanelController controller)? headerBuilder;

  /// The main axis of the layout.
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalSize = axis == Axis.horizontal ? constraints.maxWidth : constraints.maxHeight;

        final inlinePanels = <Widget>[];
        final overlayPanels = <Widget>[];

        // 1. Separate panels into inline and overlay
        final visiblePanels = <PanelController>[];
        for (final id in panelIds) {
          final panel = controller.getPanel(id);
          if (panel != null) {
            if (panel.mode == PanelMode.overlay) {
              overlayPanels.add(
                _buildOverlayPanel(context, panel, totalSize),
              );
            } else if (panel.isVisible) {
              visiblePanels.add(panel);
            }
          }
        }

        // 2. Build inline panels with resize handles
        for (var i = 0; i < visiblePanels.length; i++) {
          final panel = visiblePanels[i];
          final isLast = i == visiblePanels.length - 1;

          // Wrap LayoutPanel
          Widget panelWidget = LayoutPanel(
            controller: panel,
            headerBuilder: headerBuilder != null 
                ? (ctx, ctrl) => headerBuilder!(ctx, panel.id, ctrl) 
                : null,
            child: panelBuilder(context, panel.id),
          );

          // Handle sizing wrappers for Flex
          if (panel.sizing is FlexibleSizing) {
            final weight = (panel.sizing as FlexibleSizing).weight;
            panelWidget = Expanded(
              flex: (weight * 100).toInt(),
              child: panelWidget,
            );
          }

          inlinePanels.add(panelWidget);

          // Add resize handle if not last
          if (!isLast) {
            final nextPanel = visiblePanels[i + 1];
            if (_shouldAddHandle(panel, nextPanel)) {
              inlinePanels.add(
                PanelResizeHandle(
                  axis: axis == Axis.horizontal ? Axis.vertical : Axis.horizontal,
                  onDragUpdate: (delta) => _handleResize(
                    delta,
                    panel,
                    nextPanel,
                    totalSize,
                    visiblePanels,
                  ),
                ),
              );
            }
          }
        }

        // 3. Assemble the final stack
        return Stack(
          fit: StackFit.expand,
          children: [
            // The main flex layout
            Flex(
              direction: axis,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: inlinePanels,
            ),
            // Overlay panels
            ...overlayPanels,
          ],
        );
      },
    );
  }

  /// Determines if a resize handle should be placed between two panels.
  bool _shouldAddHandle(PanelController prev, PanelController next) {
    if (prev.isCollapsed && next.isCollapsed) return false;

    if (prev.sizing is ContentSizing && next.sizing is ContentSizing) {
      return false;
    }

    return prev.isResizable || next.isResizable;
  }

  /// Handles the drag logic for resizing panels.
  void _handleResize(
    double delta,
    PanelController prev,
    PanelController next,
    double totalSize,
    List<PanelController> visiblePanels,
  ) {
    if (prev.sizing is FixedSizing && prev.isResizable && !prev.isCollapsed) {
      final current = (prev.sizing as FixedSizing).size;
      prev.resize(current + delta);
      return;
    }

    if (next.sizing is FixedSizing && next.isResizable && !next.isCollapsed) {
      final current = (next.sizing as FixedSizing).size;
      next.resize(current - delta);
      return;
    }

    if (prev.sizing is FlexibleSizing && next.sizing is FlexibleSizing) {
      double totalWeight = 0;
      double totalFixedSize = 0;
      for (final p in visiblePanels) {
        if (p.sizing is FlexibleSizing) {
          totalWeight += (p.sizing as FlexibleSizing).weight;
        } else {
          totalFixedSize += p.effectiveSize;
        }
      }

      final availableSpace = totalSize - totalFixedSize;
      if (availableSpace <= 0) return;

      final weightDelta = (delta / availableSpace) * totalWeight;

      final prevWeight = (prev.sizing as FlexibleSizing).weight;
      final nextWeight = (next.sizing as FlexibleSizing).weight;

      prev.resize(prevWeight + weightDelta);
      next.resize(nextWeight - weightDelta);
    }
  }

  Widget _buildOverlayPanel(
    BuildContext context,
    PanelController panel,
    double totalSize,
  ) {
    final Widget content = LayoutPanel(
      controller: panel,
      headerBuilder: headerBuilder != null 
          ? (ctx, ctrl) => headerBuilder!(ctx, panel.id, ctrl) 
          : null,
      child: panelBuilder(context, panel.id),
    );

    if (!panel.isResizable || panel.isCollapsed) {
      var alignment = Alignment.center;
      if (panel.anchor == PanelAnchor.right) alignment = Alignment.centerRight;
      if (panel.anchor == PanelAnchor.left) alignment = Alignment.centerLeft;
      if (panel.anchor == PanelAnchor.top) alignment = Alignment.topCenter;
      if (panel.anchor == PanelAnchor.bottom) alignment = Alignment.bottomCenter;

      return Align(alignment: alignment, child: content);
    }

    final children = <Widget>[];
    final PanelResizeHandle handle;
    final Alignment alignment;
    final Axis direction;

    switch (panel.anchor) {
      case PanelAnchor.right:
        alignment = Alignment.centerRight;
        direction = Axis.horizontal;
        handle = PanelResizeHandle(
          onDragUpdate: (delta) => _resizeOverlay(panel, -delta),
        );
        children.addAll([handle, content]);

      case PanelAnchor.left:
        alignment = Alignment.centerLeft;
        direction = Axis.horizontal;
        handle = PanelResizeHandle(
          onDragUpdate: (delta) => _resizeOverlay(panel, delta),
        );
        children.addAll([content, handle]);

      case PanelAnchor.bottom:
        alignment = Alignment.bottomCenter;
        direction = Axis.vertical;
        handle = PanelResizeHandle(
          axis: Axis.horizontal,
          onDragUpdate: (delta) => _resizeOverlay(panel, -delta),
        );
        children.addAll([handle, content]);

      case PanelAnchor.top:
        alignment = Alignment.topCenter;
        direction = Axis.vertical;
        handle = PanelResizeHandle(
          axis: Axis.horizontal,
          onDragUpdate: (delta) => _resizeOverlay(panel, delta),
        );
        children.addAll([content, handle]);
    }

    return Align(
      alignment: alignment,
      child: Flex(
        direction: direction,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  void _resizeOverlay(PanelController panel, double delta) {
    if (panel.sizing is FixedSizing) {
      final current = (panel.sizing as FixedSizing).size;
      panel.resize(current + delta);
    }
  }
}