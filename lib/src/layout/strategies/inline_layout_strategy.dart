import 'package:flutter/widgets.dart';
import '../../core/debug_flag.dart';
import '../../models/panel_enums.dart';
import '../../models/panel_id.dart';
import '../../widgets/panels/inline_panel.dart';
import '../../widgets/internal/internal_layout_adapter.dart';
import '../../models/resolved_panel.dart';
import 'layout_context.dart';

/// Handles the linear layout of panels that share space (Row/Column behavior).
class InlineLayoutStrategy {
  const InlineLayoutStrategy();

  /// Performs layout for inline panels and resize handles.
  ///
  /// Returns a map of [PanelId] to [Rect] representing the layout bounds of each panel.
  Map<PanelId, Rect> layout({
    required LayoutContext context,
    required Size size,
    required List<ResolvedPanel> panels,
    required Axis axis,
  }) {
    final isHorizontal = axis == Axis.horizontal;
    final totalMainSpace = isHorizontal ? size.width : size.height;
    final crossSpace = isHorizontal ? size.height : size.width;

    final inlinePanels = panels.where((p) => p.config is InlinePanel).toList();

    // Sort logic
    final inlineIds = _orderInlinePanels(inlinePanels);
    final panelRects = <PanelId, Rect>{};

    double usedMainSpace = 0;
    double totalWeight = 0;
    final flexiblePanels = <ResolvedPanel>[];

    // Pass 1: Measure Fixed and Content
    for (final p in inlineIds) {
      final config = p.config as InlinePanel;
      final override = p.state.fixedPixelSizeOverride;

      // Check for layoutWeight on InternalLayoutAdapter
      final weight = config is InternalLayoutAdapter
          ? config.layoutWeight
          : null;

      if (weight != null && override == null) {
        // Flexible: Sum up animated weight
        final animatedWeight = p.effectiveSize;
        if (animatedWeight > 0) {
          flexiblePanels.add(p);
          totalWeight += animatedWeight;
        } else {
          // Effectively hidden
          if (context.hasChild(config.id)) {
            context.layoutChild(
              config.id,
              const BoxConstraints.tightFor(width: 0, height: 0),
            );
            context.positionChild(config.id, Offset.zero);
          }
        }
      } else {
        final animatedSize = p.effectiveSize;
        final isContent = config.width == null && config.height == null;

        // If not visible and not content, it takes no space but MUST be laid out
        if (animatedSize <= 0 && !isContent) {
          if (context.hasChild(config.id)) {
            context.layoutChild(
              config.id,
              const BoxConstraints.tightFor(width: 0, height: 0),
            );
            context.positionChild(config.id, Offset.zero);
          }
          panelRects[config.id] = Rect.zero;
          continue;
        }

        // Fixed or Content?
        final isFixed =
            (isHorizontal ? config.width != null : config.height != null) ||
            override != null;

        final BoxConstraints constraints;

        if (isFixed) {
          // Enforce the size from state (including animation factor)
          constraints = isHorizontal
              ? BoxConstraints.tightFor(width: animatedSize, height: crossSpace)
              : BoxConstraints.tightFor(
                  height: animatedSize,
                  width: crossSpace,
                );
        } else {
          // Content Sizing (Intrinsic)
          constraints = isHorizontal
              ? BoxConstraints(maxHeight: crossSpace)
              : BoxConstraints(maxWidth: crossSpace);
        }

        final s = context.layoutChild(config.id, constraints);
        usedMainSpace += isHorizontal ? s.width : s.height;
        panelRects[config.id] = Offset.zero & s;
        panelLayoutLog(
          'Delegate Pass 1 measured inline ${config.id.value} as $s',
        );
      }
    }

    // --- 1b. Measure Handles ---
    final handleSizes = <HandleLayoutId, Size>{};

    for (var i = 0; i < inlineIds.length - 1; i++) {
      final prev = inlineIds[i];
      final next = inlineIds[i + 1];
      final handleId = HandleLayoutId(prev.config.id, next.config.id);

      if (context.hasChild(handleId)) {
        final s = context.layoutChild(handleId, BoxConstraints.loose(size));
        handleSizes[handleId] = s;
        usedMainSpace += isHorizontal ? s.width : s.height;
      }
    }

    // Pass 2: Measure Flexible
    final freeSpace = (totalMainSpace - usedMainSpace).clamp(
      0.0,
      double.infinity,
    );
    for (final p in flexiblePanels) {
      final weight = p.effectiveSize;
      final share = totalWeight > 0 ? (weight / totalWeight) * freeSpace : 0.0;

      final constraints = isHorizontal
          ? BoxConstraints.tightFor(width: share, height: crossSpace)
          : BoxConstraints.tightFor(width: crossSpace, height: share);

      final s = context.layoutChild(p.config.id, constraints);
      panelRects[p.config.id] = Offset.zero & s;
    }

    // Pass 3: Position Inline Items (Panels + Handles)
    double currentPos = 0.0;

    for (var i = 0; i < inlineIds.length; i++) {
      final p = inlineIds[i];

      // Position Panel
      if (panelRects.containsKey(p.config.id)) {
        final s = panelRects[p.config.id]!.size;
        final offset = isHorizontal
            ? Offset(currentPos, 0)
            : Offset(0, currentPos);
        context.positionChild(p.config.id, offset);
        panelRects[p.config.id] = offset & s;
        currentPos += isHorizontal ? s.width : s.height;
      }

      // Position Handle (if exists after this panel)
      if (i < inlineIds.length - 1) {
        final next = inlineIds[i + 1];
        final handleId = HandleLayoutId(p.config.id, next.config.id);

        if (handleSizes.containsKey(handleId)) {
          final s = handleSizes[handleId]!;
          final offset = isHorizontal
              ? Offset(currentPos, 0)
              : Offset(0, currentPos);
          context.positionChild(handleId, offset);
          currentPos += isHorizontal ? s.width : s.height;
        }
      }
    }

    return panelRects;
  }

  /// Orders inline panels based on anchoring dependencies.
  ///
  /// This ensures that panels anchored to other panels are processed after their targets.
  ///
  /// **Time Complexity**: Approaches O(N^2) in the worst case (reverse dependency chain).
  /// However, since N (number of panels) is typically very small (< 20), this is negligible
  /// for UI performance. If N grows significantly, a Topological Sort (O(V+E)) should be used.
  List<ResolvedPanel> _orderInlinePanels(List<ResolvedPanel> source) {
    final ordered = <ResolvedPanel>[];
    final deferred = <ResolvedPanel>[];

    for (final p in source) {
      if (p.config.anchorTo == null) {
        ordered.add(p);
      } else {
        deferred.add(p);
      }
    }

    for (final p in deferred) {
      final targetIndex = ordered.indexWhere(
        (target) => target.config.id == p.config.anchorTo,
      );
      if (targetIndex != -1) {
        bool insertBefore =
            p.config.anchor == PanelAnchor.left ||
            p.config.anchor == PanelAnchor.top;
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
}
