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
    this.axis = Axis.horizontal,
    super.key,
  });

  /// The layout controller managing the panels.
  final PanelLayoutController panelLayoutController;

  /// The list of panel IDs to include in this area.
  final List<PanelId> panelIds;

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

            // --- 1. Separate Inline and Overlay Panels ---
            final allInlinePanels = <PanelController>[];
            final overlayPanels = <Widget>[];

            for (final panel in panels) {
              if (panel.mode == PanelMode.overlay) {
                overlayPanels.add(
                  _buildOverlayPanel(context, panel, totalSize),
                );
              } else {
                allInlinePanels.add(panel);
              }
            }

            // --- 2. Reorder Inline Panels based on anchors ---
            // Panels with anchorPanel set are moved next to their target.
            final activeInlinePanels = _orderInlinePanels(allInlinePanels);

            // Filter for visibility after reordering
            final visibleInlinePanels = activeInlinePanels.where((panel) {
              // We include invisible panels if they are NOT flexible,
              // to allow LayoutPanel to animate their size to 0.
              if (panel.isVisible) return true;
              return panel.sizing is! FlexibleSizing;
            }).toList();

            final inlineWidgets = <Widget>[];

            // --- 3. Build Inline Widgets ---
            for (var i = 0; i < visibleInlinePanels.length; i++) {
              final panel = visibleInlinePanels[i];
              final isLast = i == visibleInlinePanels.length - 1;

              // Wrap every panel in CompositedTransformTarget
              Widget panelWidget = CompositedTransformTarget(
                link: panel.layerLink,
                child: LayoutPanel(
                  key: ValueKey(panel.id),
                  panelController: panel,
                  child: panel.builder(context, panel),
                ),
              );

              if (panel.sizing is FlexibleSizing) {
                final weight = (panel.sizing as FlexibleSizing).weight;
                panelWidget = Expanded(
                  flex: (weight * 100).toInt(),
                  child: panelWidget,
                );
              }

              inlineWidgets.add(panelWidget);

              if (!isLast) {
                final nextPanel = visibleInlinePanels[i + 1];
                if (_shouldAddHandle(panel, nextPanel) &&
                    panel.isVisible &&
                    nextPanel.isVisible) {
                  inlineWidgets.add(
                    PanelResizeHandle(
                      key: ValueKey('${panel.id.value}_handle'),
                      axis: axis == Axis.horizontal
                          ? Axis.vertical
                          : Axis.horizontal,
                      onDragUpdate: (delta) => _handleResize(
                        delta,
                        panel,
                        nextPanel,
                        totalSize,
                        visibleInlinePanels,
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
                  children: inlineWidgets,
                ),
                ...overlayPanels,
              ],
            );
          },
        );
      },
    );
  }

  /// Reorders panels to respect [anchorPanel] dependencies for inline items.
  List<PanelController> _orderInlinePanels(List<PanelController> source) {
    final ordered = <PanelController>[];
    final deferred = <PanelController>[];

    // 1. Add base panels (no anchor) first
    for (final panel in source) {
      if (panel.anchorPanel == null) {
        ordered.add(panel);
      } else {
        deferred.add(panel);
      }
    }

    // 2. Insert anchored panels
    // We do a simple pass. Nested anchoring (chaining) might require multiple passes
    // or recursion, but for now we handle one level of depth or dependent order.
    // Iterating deferred list multiple times to resolve dependencies could be an enhancement.
    // For robust handling, we'll try to insert. If target not found, append to end.
    for (final panel in deferred) {
      final targetIndex = ordered.indexWhere((p) => p.id == panel.anchorPanel);
      if (targetIndex != -1) {
        // Insert based on anchor direction relative to target
        bool insertBefore = panel.anchor == PanelAnchor.left ||
            panel.anchor == PanelAnchor.top;

        // If target is right/bottom anchored itself, logic might flip depending on
        // strictly visual vs logical. Assuming logical: Left/Top = Before.
        if (insertBefore) {
          ordered.insert(targetIndex, panel);
        } else {
          ordered.insert(targetIndex + 1, panel);
        }
      } else {
        // Target not found (maybe overlay, detached, or missing).
        // Fallback: Add to end.
        ordered.add(panel);
      }
    }

    return ordered;
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
    // 1. Prepare Content (Wrapped in Target)
    // Even overlay panels can be targets for other panels.
    final Widget content = CompositedTransformTarget(
      link: panel.layerLink,
      child: LayoutPanel(
        panelController: panel,
        child: panel.builder(context, panel),
      ),
    );

    // 2. Determine Logic Strategy (Global vs Relative)
    if (panel.anchorPanel == null) {
      return _buildGlobalOverlay(panel, content);
    } else {
      return _buildRelativeOverlay(panel, content);
    }
  }

  Widget _buildGlobalOverlay(PanelController panel, Widget content) {
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

  Widget _buildRelativeOverlay(PanelController panel, Widget content) {
    // Find target
    final targetId = panel.anchorPanel;
    final targetPanel = panelLayoutController.getPanel(targetId!);

    if (targetPanel == null) {
      // Fallback if target missing: Global Anchor
      return _buildGlobalOverlay(panel, content);
    }

    // Determine follower alignment
    Alignment followerAnchor = Alignment.center;
    Alignment targetAnchor = Alignment.center;
    Offset offset = Offset.zero;

    // Logic:
    // If anchored LEFT: Attach my RIGHT edge to target's LEFT edge.
    // If anchored RIGHT: Attach my LEFT edge to target's RIGHT edge.
    switch (panel.anchor) {
      case PanelAnchor.left:
        targetAnchor = Alignment.centerLeft;
        followerAnchor = Alignment.centerRight;
        break;
      case PanelAnchor.right:
        targetAnchor = Alignment.centerRight;
        followerAnchor = Alignment.centerLeft;
        break;
      case PanelAnchor.top:
        targetAnchor = Alignment.topCenter;
        followerAnchor = Alignment.bottomCenter;
        break;
      case PanelAnchor.bottom:
        targetAnchor = Alignment.bottomCenter;
        followerAnchor = Alignment.topCenter;
        break;
    }

    // Build resize handle if needed
    // Note: Resize handle for relative panels works similarly to global,
    // but we need to package it with the content inside the Follower.
    Widget followerContent = content;
    if (panel.isResizable && !panel.isCollapsed) {
      final children = <Widget>[];
      final PanelResizeHandle handle;
      final Axis direction;

      switch (panel.anchor) {
        case PanelAnchor.right:
          // Panel is to the right of target.
          // Resize handle should be on the LEFT of the panel (between panel and target).
          // Dragging handle right increases panel size (delta positive).
          // Wait, typically resize handle is on the "free" edge.
          // IF anchored to right of target, the left edge is fixed to target.
          // So handle should be on the RIGHT edge?
          // "Settings Change" sliding out of "Settings" (Right anchored).
          // [Settings] [Change]
          // The Change panel grows to the right? Or does it slide left?
          // User said: "Settings anchored to right... settings change sliding out... anchored left to settings".
          // [Change] [Settings] | Screen Edge
          // If Change is anchored LEFT to Settings:
          // Target (Settings) Anchor: Left. Follower (Change) Anchor: Right.
          // Visual: [Change][Settings]
          // Change resize handle? Usually on the "free" edge (Left).
          //
          // Let's stick to standard behavior:
          // Handle is always on the interior side if possible, or exterior.
          // For simplicity: Handle is on the side OPPOSITE to the anchor connection?
          // If I am anchored LEFT (to my target), my RIGHT side is touched to target.
          // My LEFT side is free. Handle on Left.
          direction = Axis.horizontal;
          handle = PanelResizeHandle(
            onDragUpdate: (delta) => _resizeOverlay(panel, delta),
          );
          // Layout: [Handle] [Content]
          children.addAll([handle, content]);
          break;

        case PanelAnchor.left:
          // I am anchored RIGHT (to target).
          // Target Anchor: Right. Follower Anchor: Left.
          // Visual: [Settings][Change]
          // Free edge is Right. Handle on Right.
          direction = Axis.horizontal;
          handle = PanelResizeHandle(
            onDragUpdate: (delta) => _resizeOverlay(panel, -delta),
          );
          // Layout: [Content] [Handle]
          children.addAll([content, handle]);
          break;

        case PanelAnchor.top:
          // Free edge is Top.
          direction = Axis.vertical;
          handle = PanelResizeHandle(
            axis: Axis.horizontal,
            onDragUpdate: (delta) => _resizeOverlay(panel, delta),
          );
          children.addAll([handle, content]);
          break;

        case PanelAnchor.bottom:
          // Free edge is Bottom.
          direction = Axis.vertical;
          handle = PanelResizeHandle(
            axis: Axis.horizontal,
            onDragUpdate: (delta) => _resizeOverlay(panel, -delta),
          );
          children.addAll([content, handle]);
          break;
      }

      followerContent = Flex(
        direction: direction,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    }

    return CompositedTransformFollower(
      link: targetPanel.layerLink,
      targetAnchor: targetAnchor,
      followerAnchor: followerAnchor,
      offset: offset,
      showWhenUnlinked: false,
      child: followerContent,
    );
  }

  void _resizeOverlay(PanelController panel, double delta) {
    if (panel.sizing is FixedSizing) {
      final current = (panel.sizing as FixedSizing).size;
      panel.resize(current + delta);
    }
  }
}
