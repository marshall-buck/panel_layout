import 'package:flutter/widgets.dart';
import 'package:equatable/equatable.dart';

import '../controllers/panel_layout_controller.dart';
import 'layout_panel.dart';
import '../controllers/panel_controller.dart';
import '../models/panel_id.dart';
import '../models/panel_sizing.dart';
import '../models/panel_enums.dart';
import 'panel_resize_handle.dart';
import 'panel_area_helper.dart';

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
        // --- 1. Identify Panel Types ---
        final inlinePanels = <PanelController>[];
        final overlayPanels = <PanelController>[];

        for (final panel in panels) {
          if (panel.mode == PanelMode.detached) continue;
          if (panel.mode == PanelMode.overlay) {
            overlayPanels.add(panel);
          } else {
            inlinePanels.add(panel);
          }
        }

        // --- 2. Calculate Layout Order (Inline) ---
        // This determines geometry (who is next to whom), but NOT paint order.
        final orderedInlinePanels = _orderInlinePanels(inlinePanels)
            .where((panel) {
              if (panel.isVisible) return true;
              return panel.sizing is! FlexibleSizing;
            })
            .toList();

        // --- 3. Prepare Widgets ---
        final layoutChildren = <Widget>[];
        final inlineLayoutIds = <Object>[]; // Will contain PanelId and _HandleId
        final overlayIds = <PanelId>[];
        
        // Track which IDs are actually active/rendered to filter the children list
        final activeIds = <Object>{}; 

        // Populate inlineLayoutIds from the ORDERED and FILTERED list
        // This ensures hidden flexible panels are excluded from the Delegate.
        for (var i = 0; i < orderedInlinePanels.length; i++) {
          final panel = orderedInlinePanels[i];
          
          // Add Panel ID
          inlineLayoutIds.add(panel.id);
          activeIds.add(panel.id);

          // Check for Handle
          if (i < orderedInlinePanels.length - 1) {
            final nextPanel = orderedInlinePanels[i + 1];
            if (_shouldAddHandle(panel, nextPanel) &&
                panel.isVisible &&
                nextPanel.isVisible) {
              final handleId = _HandleId(panel.id, nextPanel.id);
              inlineLayoutIds.add(handleId);
              activeIds.add(handleId);
            }
          }
        }

        // Map to store widgets before ordering
        final widgetMap = <Object, Widget>{};

        // Create Panel Widgets (for ALL panels initially, filtered later)
        for (final panel in panels) {
          if (panel.mode == PanelMode.detached) continue;
          
          Widget child = LayoutPanel(
            key: ValueKey(panel.id),
            panelController: panel,
            child: panel.builder(context, panel),
          );

          if (panel.mode == PanelMode.overlay) {
            overlayIds.add(panel.id);
            activeIds.add(panel.id);
            
            if (panel.anchorLink != null) {
              child = CompositedTransformFollower(
                link: panel.anchorLink!,
                showWhenUnlinked: false,
                child: child,
              );
            }
          } 
          
          widgetMap[panel.id] = LayoutId(id: panel.id, child: child);
        }

        // Create Handle Widgets
        final handleWidgets = <Widget>[];
        for (final id in inlineLayoutIds) {
          if (id is _HandleId) {
             final prev = panelLayoutController.getPanel(id.prev)!;
             final next = panelLayoutController.getPanel(id.next)!;
             
             final handleWidget = LayoutId(
              id: id,
              child: PanelResizeHandle(
                key: ValueKey('${id.prev.value}_handle'),
                axis: axis == Axis.horizontal ? Axis.vertical : Axis.horizontal,
                onDragUpdate: (delta) => _handleResize(
                  delta,
                  prev,
                  next,
                  axis == Axis.horizontal
                      ? context.size?.width ?? 0
                      : context.size?.height ?? 0,
                  orderedInlinePanels, // Pass the filtered list!
                ),
              ),
            );
            handleWidgets.add(handleWidget);
          }
        }

        // --- 4. Construct Render Order ---
        // We create a unified list of paintable items (Panels and Handles) and sort them.
        // This decouples paint order (Z-index) from layout order.
        
        final paintItems = <PaintItem>[];

        // 4a. Add Panels
        for (var i = 0; i < panelIds.length; i++) {
          final id = panelIds[i];
          if (activeIds.contains(id) && widgetMap.containsKey(id)) {
            final panel = panelLayoutController.getPanel(id);
            if (panel != null) {
              paintItems.add(PaintItem(
                id: id,
                widget: widgetMap[id]!,
                zIndex: panel.zIndex,
                isHandle: false,
                originalIndex: i,
              ));
            }
          }
        }

        // 4b. Add Handles
        // Handles are part of the inline layer, so we default them to zIndex 0.
        // They should typically render ABOVE inline panels of the same z-index.
        for (var i = 0; i < handleWidgets.length; i++) {
          paintItems.add(PaintItem(
            id: const Object(), // Handle ID not strictly needed for sorting distinct from widget
            widget: handleWidgets[i],
            zIndex: 0, 
            isHandle: true,
            originalIndex: panelIds.length + i, // Arbitrary order after panels
          ));
        }

        // 4c. Sort
        paintItems.sort((a, b) {
          // 1. Z-Index
          final zComp = a.zIndex.compareTo(b.zIndex);
          if (zComp != 0) return zComp;

          // 2. Handles on top of Panels (for same Z-index)
          if (a.isHandle != b.isHandle) {
            return a.isHandle ? 1 : -1;
          }

          // 3. Stable Sort (Original Index)
          return a.originalIndex.compareTo(b.originalIndex);
        });

        // 4d. Populate Children
        layoutChildren.addAll(paintItems.map((item) => item.widget));

        return CustomMultiChildLayout(
          delegate: _PanelLayoutDelegate(
            panelLayoutController: panelLayoutController,
            inlineLayoutIds: inlineLayoutIds,
            overlayIds: overlayIds,
            axis: axis,
            textDirection: Directionality.of(context),
          ),
          children: layoutChildren,
        );
      },
    );
  }

  // _buildOverlayChild removed as it is now integrated into loop
  // _sortOverlays removed as we respect user order


  List<PanelController> _orderInlinePanels(List<PanelController> source) {
    final ordered = <PanelController>[];
    final deferred = <PanelController>[];

    for (final panel in source) {
      if (panel.anchorPanel == null) {
        ordered.add(panel);
      } else {
        deferred.add(panel);
      }
    }

    for (final panel in deferred) {
      final targetIndex = ordered.indexWhere((p) => p.id == panel.anchorPanel);
      if (targetIndex != -1) {
        bool insertBefore =
            panel.anchor == PanelAnchor.left || panel.anchor == PanelAnchor.top;
        if (insertBefore) {
          ordered.insert(targetIndex, panel);
        } else {
          ordered.insert(targetIndex + 1, panel);
        }
      } else {
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
}

class _HandleId extends Equatable {
  final PanelId prev;
  final PanelId next;
  const _HandleId(this.prev, this.next);
  @override
  List<Object?> get props => [prev, next];
}

class _PanelLayoutDelegate extends MultiChildLayoutDelegate {
  _PanelLayoutDelegate({
    required this.panelLayoutController,
    required this.inlineLayoutIds,
    required this.overlayIds,
    required this.axis,
    required this.textDirection,
  });

  final PanelLayoutController panelLayoutController;
  final List<Object> inlineLayoutIds; // PanelId or _HandleId
  final List<PanelId> overlayIds;
  final Axis axis;
  final TextDirection textDirection;

  @override
  void performLayout(Size size) {
    final isHorizontal = axis == Axis.horizontal;
    final totalMainSpace = isHorizontal ? size.width : size.height;
    final crossSpace = isHorizontal ? size.height : size.width;

    double usedMainSpace = 0;
    double totalWeight = 0;
    
    // Track sizes for flexible logic
    final flexiblePanels = <PanelId>[];
    // Track geometry for overlay referencing
    final panelRects = <PanelId, Rect>{};
    // Track handle sizes
    final handleSizes = <_HandleId, Size>{};

    // --- Pass 1: Measure Fixed, Content, and Handles ---
    for (final id in inlineLayoutIds) {
      if (id is _HandleId) {
        if (hasChild(id)) {
           // Handles are fixed size widgets (usually 8px or so)
           // We respect their intrinsic size
           final s = layoutChild(
             id, 
             BoxConstraints.loose(size), // Allow it to be as big as it wants?
           );
           handleSizes[id] = s;
           usedMainSpace += isHorizontal ? s.width : s.height;
        }
      } else if (id is PanelId) {
        final panel = panelLayoutController.getPanel(id);
        if (panel != null) {
          if (panel.sizing is FlexibleSizing) {
            if (panel.isVisible) {
              flexiblePanels.add(id);
              totalWeight += (panel.sizing as FlexibleSizing).weight;
            }
          } else {
            // Fixed or Content
            // Layout with loose constraints first to get content size
            // For FixedSizing, LayoutPanel returns SizedBox, so it respects it.
            // For ContentSizing, it returns content size.
            // We use 0-unlimited for main axis.
            final constraints = isHorizontal 
                ? BoxConstraints(maxHeight: crossSpace)
                : BoxConstraints(maxWidth: crossSpace);
            
            final s = layoutChild(id, constraints);
            usedMainSpace += isHorizontal ? s.width : s.height;
            
            // Store size (position will be set in Pass 3)
            // We temporarily store Rect with 0 offset.
            panelRects[id] = Offset.zero & s;
          }
        }
      }
    }

    // --- Pass 2: Measure Flexible Panels ---
    final freeSpace = (totalMainSpace - usedMainSpace).clamp(0.0, double.infinity);
    
    for (final id in flexiblePanels) {
      final panel = panelLayoutController.getPanel(id)!;
      final weight = (panel.sizing as FlexibleSizing).weight;
      final share = totalWeight > 0 ? (weight / totalWeight) * freeSpace : 0.0;
      
      final constraints = isHorizontal
          ? BoxConstraints.tightFor(width: share, height: crossSpace)
          : BoxConstraints.tightFor(width: crossSpace, height: share);
          
      final s = layoutChild(id, constraints);
      panelRects[id] = Offset.zero & s;
    }

    // --- Pass 3: Position Inline Items ---
    double currentPos = 0.0;
    
    for (final id in inlineLayoutIds) {
      if (id is _HandleId) {
        if (hasChild(id) && handleSizes.containsKey(id)) {
           final s = handleSizes[id]!;
           
           positionChild(
             id, 
             isHorizontal 
                 ? Offset(currentPos, 0) 
                 : Offset(0, currentPos)
           );
           
           currentPos += isHorizontal ? s.width : s.height;
        }
      } else if (id is PanelId) {
        if (panelRects.containsKey(id)) {
           final rect = panelRects[id]!;
           positionChild(
             id, 
             isHorizontal 
                 ? Offset(currentPos, 0) 
                 : Offset(0, currentPos)
           );
           
           // Update Rect with actual position
           panelRects[id] = (isHorizontal 
               ? Offset(currentPos, 0) 
               : Offset(0, currentPos)) & rect.size;
               
           currentPos += isHorizontal ? rect.width : rect.height;
        }
      }
    }

    // --- Pass 4: Layout Overlays ---
    for (final id in overlayIds) {
      final panel = panelLayoutController.getPanel(id);
      if (panel == null || !hasChild(id)) continue;

      // Determine Anchor Rect
      Rect anchorRect;
      if (panel.anchorPanel != null && panelRects.containsKey(panel.anchorPanel)) {
        anchorRect = panelRects[panel.anchorPanel]!;
      } else {
        // Global
        anchorRect = Offset.zero & size;
      }

      // External Anchor (LayerLink) special case:
      if (panel.anchorLink != null) {
          // Just give it loose constraints and position at 0,0
          layoutChild(id, BoxConstraints.loose(size));
          positionChild(id, Offset.zero);
          continue;
      }

      // Measure Overlay Child
      final crossAlign = panel.crossAxisAlignment ?? CrossAxisAlignment.stretch;
      BoxConstraints childConstraints = BoxConstraints.loose(size);

      // If anchored and stretching, enforce tight constraints on the cross axis
      if (panel.anchorPanel != null && panelRects.containsKey(panel.anchorPanel)) {
        final anchorRect = panelRects[panel.anchorPanel]!;
        
        if (crossAlign == CrossAxisAlignment.stretch) {
          switch (panel.anchor) {
            case PanelAnchor.left:
            case PanelAnchor.right:
              // Match Height
              childConstraints = BoxConstraints(
                minHeight: anchorRect.height,
                maxHeight: anchorRect.height,
                minWidth: 0,
                maxWidth: size.width, 
              );
              break;
            case PanelAnchor.top:
            case PanelAnchor.bottom:
              // Match Width
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

      final childSize = layoutChild(id, childConstraints);
      
      // Calculate Position
      Offset position = Offset.zero;
      
      // Resolve Alignment/Anchor
      Alignment alignment = Alignment.center;
      if (panel.alignment != null) {
        alignment = panel.alignment!.resolve(textDirection);
      } else {
         // Default anchors
         switch (panel.anchor) {
           case PanelAnchor.left:
             alignment = Alignment.centerLeft;
           case PanelAnchor.right:
             alignment = Alignment.centerRight;
           case PanelAnchor.top:
             alignment = Alignment.topCenter;
           case PanelAnchor.bottom:
             alignment = Alignment.bottomCenter;
         }
      }

      // Logic:
      // If Anchor is Global (no anchorPanel), alignment positions it within the global rect.
      // If Anchor is Relative (anchorPanel exists):
      //    Left -> Right edge of overlay touches Left edge of Anchor.
      //    Right -> Left edge of overlay touches Right edge of Anchor.
      //    Top -> Bottom edge of overlay touches Top edge of Anchor.
      //    Bottom -> Top edge of overlay touches Bottom edge of Anchor.
      
      if (panel.anchorPanel != null) {
        // Relative Positioning
        // We use the same logic as _buildRelativeOverlay used to do.
        
        // Alignment determines the "slide" along the edge? 
        // e.g. Anchor Left + Align Center -> Vertically centered relative to anchor.
        
        double dx = 0;
        double dy = 0;
        
        switch (panel.anchor) {
          case PanelAnchor.left:
             // To the Left of Anchor
             dx = anchorRect.left - childSize.width;
             // Vertical Alignment
             dy = _alignAxis(anchorRect.top, anchorRect.height, childSize.height, alignment.y);
             break;
          case PanelAnchor.right:
             // To the Right of Anchor
             dx = anchorRect.right;
             // Vertical Alignment
             dy = _alignAxis(anchorRect.top, anchorRect.height, childSize.height, alignment.y);
             break;
          case PanelAnchor.top:
             // Above Anchor
             dy = anchorRect.top - childSize.height;
             // Horizontal Alignment
             dx = _alignAxis(anchorRect.left, anchorRect.width, childSize.width, alignment.x);
             break;
          case PanelAnchor.bottom:
             // Below Anchor
             dy = anchorRect.bottom;
             // Horizontal Alignment
             dx = _alignAxis(anchorRect.left, anchorRect.width, childSize.width, alignment.x);
             break;
        }
        position = Offset(dx, dy);
        
      } else {
        // Global Positioning
        final rect = alignment.inscribe(childSize, anchorRect);
        position = rect.topLeft;
      }
      
      positionChild(id, position);
      
      // Store rect for subsequent overlays to anchor to
      panelRects[id] = position & childSize;
    }
  }
  
  double _alignAxis(double start, double length, double childLength, double alignPct) {
      // alignPct is -1.0 to 1.0
      // -1 -> start
      // 0 -> center
      // 1 -> end
      
      // normalized 0.0 to 1.0
      final t = (alignPct + 1.0) / 2.0;
      return start + (length - childLength) * t;
  }

  @override
  bool shouldRelayout(_PanelLayoutDelegate oldDelegate) {
    // If inlineLayoutIds changed, or overlayIds changed, or sizing changed.
    // PanelController notifies listeners which triggers ListenableBuilder which rebuilds PanelArea.
    // So a new Delegate is created.
    return oldDelegate.panelLayoutController != panelLayoutController ||
           oldDelegate.inlineLayoutIds != inlineLayoutIds ||
           oldDelegate.overlayIds != overlayIds; 
           // Equality on lists check reference or content? Default is ref.
           // Equatable helps but lists in Dart are not Equatable by default.
           // However, PanelArea rebuilds completely on change, so usually we just return true or check controller.
           // For optimization we might want deep compare but usually layout is cheap enough.
  }
}