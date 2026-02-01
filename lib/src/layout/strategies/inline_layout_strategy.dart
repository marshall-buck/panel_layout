import 'package:flutter/widgets.dart';
import '../../core/debug_flag.dart';
import '../../core/performance_monitor.dart';
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

    // Trust that the delegate passed them in the correct dependency order.
    final inlineIds = inlinePanels;
    final panelRects = <PanelId, Rect>{};

    double usedMainSpace = 0;
    double totalWeight = 0;
    final flexiblePanels = <ResolvedPanel>[];

    PerformanceMonitor.start('InlineStrategy.Pass1');
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

        PerformanceMonitor.start('LayoutChild:${config.id.value}');
        final s = context.layoutChild(config.id, constraints);
        PerformanceMonitor.end('LayoutChild:${config.id.value}');

        usedMainSpace += isHorizontal ? s.width : s.height;
        panelRects[config.id] = Offset.zero & s;
        panelLayoutLog(
          'Delegate Pass 1 measured inline ${config.id.value} as $s',
        );
      }
    }
    PerformanceMonitor.end('InlineStrategy.Pass1');

    PerformanceMonitor.start('InlineStrategy.Pass1b');
    // --- 1b. Measure Handles ---
    final handleSizes = <HandleLayoutId, Size>{};

    for (var i = 0; i < inlineIds.length - 1; i++) {
      final prev = inlineIds[i];
      final next = inlineIds[i + 1];
      final handleId = HandleLayoutId(prev.config.id, next.config.id);

      if (context.hasChild(handleId)) {
        // Only layout/show handle if both neighbors are effectively visible
        if ((prev.state.visible || prev.visualFactor > 0) &&
            (next.state.visible || next.visualFactor > 0)) {
          final s = context.layoutChild(handleId, BoxConstraints.loose(size));
          handleSizes[handleId] = s;
          usedMainSpace += isHorizontal ? s.width : s.height;
        } else {
          // Hide handle (0 size)
          context.layoutChild(
            handleId,
            const BoxConstraints.tightFor(width: 0, height: 0),
          );
        }
      }
    }
    PerformanceMonitor.end('InlineStrategy.Pass1b');

    PerformanceMonitor.start('InlineStrategy.Pass2');
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
    PerformanceMonitor.end('InlineStrategy.Pass2');

    PerformanceMonitor.start('InlineStrategy.Pass3');
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
    PerformanceMonitor.end('InlineStrategy.Pass3');

    return panelRects;
  }
}
