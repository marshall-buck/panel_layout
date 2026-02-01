import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import '../core/debug_flag.dart';
import '../core/performance_monitor.dart';
import '../models/panel_id.dart';
import '../widgets/panels/base_panel.dart';
import '../state/panel_state_manager.dart';
import '../models/panel_style.dart';
import '../models/resolved_panel.dart';
import 'panel_layout_engine.dart';
import 'strategies/layout_context.dart';
import 'strategies/inline_layout_strategy.dart';
import 'strategies/overlay_layout_strategy.dart';

/// A delegate that calculates the layout of panels based on [ResolvedPanel].
///
/// This is the "brain" of the layout engine, responsible for positioning
/// inline and overlay panels according to their anchors and sizes.
///
/// It delegates the actual calculation to:
/// - [InlineLayoutStrategy] for the grid/flex layout.
/// - [OverlayLayoutStrategy] for floating panels.
@internal
class PanelAreaDelegate extends MultiChildLayoutDelegate
    implements LayoutContext {
  PanelAreaDelegate({
    required this.stateManager,
    required this.configs,
    required this.style,
    required this.engine,
    required this.axis,
    required this.textDirection,
  }) : super(relayout: stateManager);

  final PanelStateManager stateManager;
  final Map<PanelId, BasePanel> configs;
  final PanelStyle style;
  final PanelLayoutEngine engine;

  /// The main axis of the layout (Horizontal = Row-like, Vertical = Column-like).
  final Axis axis;

  /// The text direction (for RTL support).
  final TextDirection textDirection;

  static const _inlineStrategy = InlineLayoutStrategy();
  static const _overlayStrategy = OverlayLayoutStrategy();

  @override
  void performLayout(Size size) {
    PerformanceMonitor.start('PanelAreaDelegate.performLayout');
    
    PerformanceMonitor.start('Engine.createLayoutData');
    // Generate fresh layout data from state
    final panels = engine.createLayoutData(
      uniquePanelConfigs: configs,
      config: style,
      stateManager: stateManager,
    );
    PerformanceMonitor.end('Engine.createLayoutData');

    PerformanceMonitor.start('Engine.calculateLayoutOrder');
    // Sort panels based on dependency order (AnchorTo) for the Inline Strategy.
    // This ensures that if Panel B is anchored to Panel A, A appears first in the list.
    final orderedPanels = engine.calculateLayoutOrder(panels);
    PerformanceMonitor.end('Engine.calculateLayoutOrder');

    panelLayoutLog('Delegate performLayout with ${panels.length} panels');

    PerformanceMonitor.start('InlineStrategy.layout');
    final inlineRects = _inlineStrategy.layout(
      context: this,
      size: size,
      panels: orderedPanels, // Pass the ordered list
      axis: axis,
    );
    PerformanceMonitor.end('InlineStrategy.layout');

    PerformanceMonitor.start('OverlayStrategy.layout');
    _overlayStrategy.layout(
      context: this,
      size: size,
      panels: panels,
      inlineRects: inlineRects,
      textDirection: textDirection,
    );
    PerformanceMonitor.end('OverlayStrategy.layout');
    
    PerformanceMonitor.end('PanelAreaDelegate.performLayout');
  }

  @override
  bool shouldRelayout(PanelAreaDelegate oldDelegate) {
    // If configs or style change, we must relayout.
    // Changes to state are handled by super(relayout: stateManager).
    
    // OPTIMIZATION: Check for map equality instead of identity.
    // PanelArea.build creates a new Map every time, so identity check always fails.
    if (oldDelegate.configs != configs) {
      if (!mapEquals(oldDelegate.configs, configs)) {
        return true;
      }
    }

    return oldDelegate.style != style ||
        oldDelegate.axis != axis ||
        oldDelegate.textDirection != textDirection;
  }
}
