import 'package:flutter/widgets.dart';

import 'panel_layout_controller.dart';
import 'layout_panel.dart';
import 'panel_controller.dart';
import 'panel_data.dart';
import 'panel_resize_handle.dart';

/// A smart container that orchestrates the layout of a group of panels.
class PanelArea extends StatelessWidget {
  /// Creates a [PanelArea].
  const PanelArea({
    required this.panelLayoutController,
    required this.panelIds,
    required this.panelBuilder,
    this.axis = Axis.horizontal,
    super.key,
  });

  /// The layout controller managing the panels.
  final PanelLayoutController panelLayoutController;

  /// The list of panel IDs to include in this area.
  final List<PanelId> panelIds;

  /// Builder to provide the widget content for a panel.
  final Widget Function(BuildContext context, PanelId id) panelBuilder;

  /// The main axis of the layout.
  final Axis axis;

  @override
  Widget build(BuildContext context) {
    final panels = panelIds
        .map((id) => panelLayoutController.getPanel(id))
        .whereType<PanelController>()
        .toList();

    return ListenableBuilder(
      listenable: Listenable.merge(panels),
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final totalSize = axis == Axis.horizontal
                ? constraints.maxWidth
                : constraints.maxHeight;

            final inlinePanels = <Widget>[];
            final overlayPanels = <Widget>[];
            final activeInlinePanels = <PanelController>[];

            for (final panel in panels) {
              if (panel.mode == PanelMode.overlay) {
                overlayPanels.add(
                  _buildOverlayPanel(context, panel, totalSize),
                );
              } else {
                // We include invisible panels if they are NOT flexible,
                // to allow LayoutPanel to animate their size to 0.
                // Flexible panels must be removed when hidden because Expanded
                // would force them to take space even if empty.
                if (panel.isVisible || panel.sizing is! FlexibleSizing) {
                  activeInlinePanels.add(panel);
                }
              }
            }

            for (var i = 0; i < activeInlinePanels.length; i++) {
              final panel = activeInlinePanels[i];
              final isLast = i == activeInlinePanels.length - 1;

              Widget panelWidget = LayoutPanel(
                panelController: panel,
                child: panelBuilder(context, panel.id),
              );

              if (panel.sizing is FlexibleSizing) {
                final weight = (panel.sizing as FlexibleSizing).weight;
                panelWidget = Expanded(
                  flex: (weight * 100).toInt(),
                  child: panelWidget,
                );
              }

              inlinePanels.add(panelWidget);

              if (!isLast) {
                final nextPanel = activeInlinePanels[i + 1];
                if (_shouldAddHandle(panel, nextPanel) &&
                    panel.isVisible &&
                    nextPanel.isVisible) {
                  inlinePanels.add(
                    PanelResizeHandle(
                      axis: axis == Axis.horizontal
                          ? Axis.vertical
                          : Axis.horizontal,
                      onDragUpdate: (delta) => _handleResize(
                        delta,
                        panel,
                        nextPanel,
                        totalSize,
                        activeInlinePanels,
                      ),
                    ),
                  );
                }
              }
            }

            return Stack(
              fit: StackFit.expand,
              children: [
                Flex(
                  direction: axis,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: inlinePanels,
                ),
                ...overlayPanels,
              ],
            );
          },
        );
      },
    );
  }

  bool _shouldAddHandle(PanelController prev, PanelController next) {
    if (prev.isCollapsed && next.isCollapsed) return false;
    if (prev.sizing is ContentSizing && next.sizing is ContentSizing) {
      return false;
    }
    return prev.isResizable || next.isResizable;
  }

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
      panelController: panel,
      child: panelBuilder(context, panel.id),
    );

    if (!panel.isResizable || panel.isCollapsed) {
      var alignment = Alignment.center;
      if (panel.anchor == PanelAnchor.right) alignment = Alignment.centerRight;
      if (panel.anchor == PanelAnchor.left) alignment = Alignment.centerLeft;
      if (panel.anchor == PanelAnchor.top) alignment = Alignment.topCenter;
      if (panel.anchor == PanelAnchor.bottom) {
        alignment = Alignment.bottomCenter;
      }

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
