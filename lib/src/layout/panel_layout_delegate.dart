import 'package:flutter/widgets.dart';
import '../models/panel_enums.dart';
import '../models/panel_id.dart';
import 'layout_data.dart';

/// A delegate that calculates the layout of panels based on [PanelLayoutData].
///
/// This is the "brain" of the layout engine, responsible for positioning
/// inline and overlay panels according to their anchors and sizes.
class PanelLayoutDelegate extends MultiChildLayoutDelegate {
  PanelLayoutDelegate({
    required this.panels,
    required this.axis,
    required this.textDirection,
  });

  /// The list of all panels to be laid out.
  final List<PanelLayoutData> panels;

  /// The main axis of the layout (Horizontal = Row-like, Vertical = Column-like).
  final Axis axis;

  /// The text direction (for RTL support).
  final TextDirection textDirection;

  @override
  void performLayout(Size size) {
    final isHorizontal = axis == Axis.horizontal;
    final totalMainSpace = isHorizontal ? size.width : size.height;
    final crossSpace = isHorizontal ? size.height : size.width;

    final inlinePanels = <PanelLayoutData>[];
    final overlayPanels = <PanelLayoutData>[];

    for (final p in panels) {
      if (p.config.mode == PanelMode.overlay) {
        overlayPanels.add(p);
      } else if (p.config.mode == PanelMode.inline) {
        inlinePanels.add(p);
      }
    }

    // --- 1. Inline Layout ---
    final inlineIds = _orderInlinePanels(inlinePanels);
    final panelRects = <PanelId, Rect>{};
    
    double usedMainSpace = 0;
    double totalWeight = 0;
    final flexiblePanels = <PanelLayoutData>[];

    // Pass 1: Measure Fixed and Content
    for (final p in inlineIds) {
      if (p.config.flex != null) {
        if (p.state.visible) {
          flexiblePanels.add(p);
          totalWeight += p.config.flex!;
        }
      } else {
        // Fixed or Content?
        // If config.width/height is set, it's Fixed.
        // We use state.size which should match the config/user-drag value.
        final isFixed = isHorizontal ? p.config.width != null : p.config.height != null;
        
        final BoxConstraints constraints;
        
        if (isFixed) {
           // Enforce the size from state
           constraints = isHorizontal
               ? BoxConstraints.tightFor(width: p.state.size, height: crossSpace)
               : BoxConstraints.tightFor(height: p.state.size, width: crossSpace);
        } else {
           // Content Sizing (Intrinsic)
           constraints = isHorizontal 
              ? BoxConstraints(maxHeight: crossSpace)
              : BoxConstraints(maxWidth: crossSpace);
        }
        
        final s = layoutChild(p.config.id, constraints);
        usedMainSpace += isHorizontal ? s.width : s.height;
        panelRects[p.config.id] = Offset.zero & s;
      }
    }

    // --- 1b. Measure Handles ---
    // We expect handles between adjacent visible inline panels (if resizable).
    // Note: The Widget tree determines if a handle *exists*. We just layout if present.
    final handleSizes = <HandleLayoutId, Size>{};
    
    for (var i = 0; i < inlineIds.length - 1; i++) {
      final prev = inlineIds[i];
      final next = inlineIds[i+1];
      final handleId = HandleLayoutId(prev.config.id, next.config.id);
      
      if (hasChild(handleId)) {
        // Handles are typically fixed size (e.g. 4px wide)
        final s = layoutChild(handleId, BoxConstraints.loose(size));
        handleSizes[handleId] = s;
        usedMainSpace += isHorizontal ? s.width : s.height;
      }
    }

    // Pass 2: Measure Flexible
    final freeSpace = (totalMainSpace - usedMainSpace).clamp(0.0, double.infinity);
    for (final p in flexiblePanels) {
      final weight = p.config.flex!;
      final share = totalWeight > 0 ? (weight / totalWeight) * freeSpace : 0.0;
      
      final constraints = isHorizontal
          ? BoxConstraints.tightFor(width: share, height: crossSpace)
          : BoxConstraints.tightFor(width: crossSpace, height: share);
          
      final s = layoutChild(p.config.id, constraints);
      panelRects[p.config.id] = Offset.zero & s;
    }

    // Pass 3: Position Inline Items (Panels + Handles)
    double currentPos = 0.0;
    
    for (var i = 0; i < inlineIds.length; i++) {
       final p = inlineIds[i];
       
       // Position Panel
       if (panelRects.containsKey(p.config.id)) {
          final s = panelRects[p.config.id]!.size;
          final offset = isHorizontal ? Offset(currentPos, 0) : Offset(0, currentPos);
          positionChild(p.config.id, offset);
          panelRects[p.config.id] = offset & s;
          currentPos += isHorizontal ? s.width : s.height;
       }
       
       // Position Handle (if exists after this panel)
       if (i < inlineIds.length - 1) {
         final next = inlineIds[i+1];
         final handleId = HandleLayoutId(p.config.id, next.config.id);
         
         if (handleSizes.containsKey(handleId)) {
           final s = handleSizes[handleId]!;
           final offset = isHorizontal ? Offset(currentPos, 0) : Offset(0, currentPos);
           positionChild(handleId, offset);
           currentPos += isHorizontal ? s.width : s.height;
         }
       }
    }

    // --- 2. Overlay Layout ---
    for (final p in overlayPanels) {
      if (!hasChild(p.config.id)) continue;

      // Determine Anchor Rect
      Rect anchorRect;
      if (p.config.anchorTo != null && panelRects.containsKey(p.config.anchorTo)) {
        anchorRect = panelRects[p.config.anchorTo]!;
      } else {
        anchorRect = Offset.zero & size;
      }

      // External Anchor (LayerLink) special case
      if (p.config.anchorLink != null) {
          layoutChild(p.config.id, BoxConstraints.loose(size));
          positionChild(p.config.id, Offset.zero);
          continue;
      }

      // Measure Overlay
      final crossAlign = p.config.crossAxisAlignment ?? CrossAxisAlignment.stretch;
      BoxConstraints childConstraints = BoxConstraints.loose(size);

      if (p.config.anchorTo != null && panelRects.containsKey(p.config.anchorTo)) {
        if (crossAlign == CrossAxisAlignment.stretch) {
          switch (p.config.anchor) {
            case PanelAnchor.left:
            case PanelAnchor.right:
              childConstraints = BoxConstraints.tightFor(height: anchorRect.height, width: null);
            case PanelAnchor.top:
            case PanelAnchor.bottom:
              childConstraints = BoxConstraints.tightFor(width: anchorRect.width, height: null);
          }
        }
      }

      // Measure Overlay
      final childSize = layoutChild(p.config.id, childConstraints);
      
      // Calculate Position
      Offset position;
      final alignment = (p.config.alignment ?? _defaultAlignment(p.config.anchor)).resolve(textDirection);

      if (p.config.anchorTo != null) {
        // Relative Positioning
        double dx = 0;
        double dy = 0;
        switch (p.config.anchor) {
          case PanelAnchor.left:
            dx = anchorRect.left - childSize.width;
            dy = _alignAxis(anchorRect.top, anchorRect.height, childSize.height, alignment.y);
          case PanelAnchor.right:
            dx = anchorRect.right;
            dy = _alignAxis(anchorRect.top, anchorRect.height, childSize.height, alignment.y);
          case PanelAnchor.top:
            dy = anchorRect.top - childSize.height;
            dx = _alignAxis(anchorRect.left, anchorRect.width, childSize.width, alignment.x);
          case PanelAnchor.bottom:
            dy = anchorRect.bottom;
            dx = _alignAxis(anchorRect.left, anchorRect.width, childSize.width, alignment.x);
        }
        position = Offset(dx, dy);
      } else {
        // Global Positioning
        final rect = alignment.inscribe(childSize, anchorRect);
        position = rect.topLeft;
      }

      positionChild(p.config.id, position);
      panelRects[p.config.id] = position & childSize;
    }
  }

  Alignment _defaultAlignment(PanelAnchor anchor) {
    switch (anchor) {
      case PanelAnchor.left: return Alignment.centerLeft;
      case PanelAnchor.right: return Alignment.centerRight;
      case PanelAnchor.top: return Alignment.topCenter;
      case PanelAnchor.bottom: return Alignment.bottomCenter;
    }
  }

  double _alignAxis(double start, double length, double childLength, double alignPct) {
      final t = (alignPct + 1.0) / 2.0;
      return start + (length - childLength) * t;
  }

  List<PanelLayoutData> _orderInlinePanels(List<PanelLayoutData> source) {
    // Ported from PanelArea logic
    final ordered = <PanelLayoutData>[];
    final deferred = <PanelLayoutData>[];

    for (final p in source) {
      if (p.config.anchorTo == null) {
        ordered.add(p);
      } else {
        deferred.add(p);
      }
    }

    for (final p in deferred) {
      final targetIndex = ordered.indexWhere((target) => target.config.id == p.config.anchorTo);
      if (targetIndex != -1) {
        bool insertBefore = p.config.anchor == PanelAnchor.left || p.config.anchor == PanelAnchor.top;
        if (insertBefore) {
          ordered.insert(targetIndex, p);
        } else {
          ordered.insert(targetIndex + 1, p);
        }
      } else {
        ordered.add(p);
      }
    }
    return ordered;
  }

  @override
  bool shouldRelayout(PanelLayoutDelegate oldDelegate) {
    // In the engine, we'll re-create the delegate if the configuration or state changes.
    return true; 
  }
}
