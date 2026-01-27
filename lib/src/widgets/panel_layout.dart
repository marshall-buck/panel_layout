import 'package:flutter/widgets.dart';

import '../models/panel_enums.dart';
import '../models/panel_id.dart';
import '../state/panel_scope.dart';
import '../state/panel_data_scope.dart';
import '../state/panel_state_manager.dart';
import '../layout/panel_style.dart';
import '../layout/layout_data.dart';
import '../layout/panel_layout_delegate.dart';
import '../layout/panel_resizing.dart';
import '../layout/panel_layout_engine.dart';
import '../controllers/panel_layout_controller.dart';
import 'widgets.dart';
import 'animation/animated_panel.dart';
import 'internal/panel_resize_handle.dart';
import 'internal/internal_layout_adapter.dart';

/// The root widget of the panel layout system.
///
/// [PanelLayout] is a declarative widget that manages a list of [BasePanel] children,
/// orchestrating their layout, sizing, and animations.
///
/// ### Features:
/// - **Declarative Configuration**: Define panels as a list of [InlinePanel] and [OverlayPanel] widgets.
/// - **State Management**: Internally tracks panel sizes (from user resizing) and visibility/collapse states.
/// - **Controller**: Optionally accepts a [PanelLayoutController] for external programmatic control.
/// - **Animations**: Automatically handles size and opacity transitions when panel state changes.
/// - **Resizing**: Renders [PanelResizeHandle]s between adjacent resizable inline panels.
///
/// ### Example:
/// ```dart
/// PanelLayout(
///   controller: myController,
///   children: [
///     InlinePanel(
///       id: PanelId('sidebar'),
///       width: 250,
///       child: Sidebar(),
///     ),
///     InlinePanel(
///       id: PanelId('content'),
///       flex: 1,
///       child: MainContent(),
///     ),
///   ],
/// )
/// ```
class PanelLayout extends StatefulWidget {
  /// Creates a declarative panel layout.
  const PanelLayout({
    required this.children,
    this.controller,
    this.style,
    this.onResizeStart,
    this.onResizeEnd,
    super.key,
  });

  /// The list of declarative panel configurations or standard widgets.
  ///
  /// - [BasePanel]s (like [InlinePanel]) allow for full configuration (sizing, anchoring).
  /// - Standard [Widget]s are automatically wrapped in an internal adapter that fills remaining space (flex=1).
  final List<Widget> children;

  /// An optional controller to manipulate panel state programmatically.
  ///
  /// If provided, you must dispose of it yourself. If not provided,
  /// the layout creates and manages its own internal controller.
  final PanelLayoutController? controller;

  /// The configuration for styling and behavior.
  final PanelStyle? style;

  /// Optional callback called when a user begins dragging a resize handle.
  final VoidCallback? onResizeStart;

  /// Optional callback called when a user finishes dragging a resize handle.
  final VoidCallback? onResizeEnd;

  /// Retrieves the [PanelLayoutController] from the closest [PanelScope] ancestor.
  static PanelLayoutController of(BuildContext context) {
    return PanelScope.of(context);
  }

  @override
  State<PanelLayout> createState() => _PanelLayoutState();
}

class _PanelLayoutState extends State<PanelLayout>
    with TickerProviderStateMixin
    implements PanelLayoutStateInterface {
  late final PanelStateManager _stateManager;
  late Axis _cachedAxis;
  static const _engine = PanelLayoutEngine();

  PanelLayoutController? _internalController;
  PanelLayoutController get _effectiveController =>
      widget.controller ?? _internalController!;

  late List<BasePanel> _processedChildren;

  // Track previous frame's constraints/ratio for calculations
  BoxConstraints? _lastConstraints;
  bool _wasAnimating = false;

  @override
  void initState() {
    super.initState();
    _processedChildren = _processChildren(widget.children);
    _cachedAxis = _engine.validateAndComputeAxis(_processedChildren);
    _stateManager = PanelStateManager();
    _stateManager.addListener(_onStateChange);
    if (widget.controller == null) {
      _internalController = PanelLayoutController();
    }
    _reconcileState();
    _effectiveController.attach(this);
  }

  List<BasePanel> _processChildren(List<Widget> children) {
    final result = <BasePanel>[];
    int adapterCount = 0;

    for (final child in children) {
      if (child is BasePanel) {
        result.add(child);
      } else {
        // Auto-wrap standard widgets
        final id = PanelId('auto_panel_$adapterCount');
        adapterCount++;
        result.add(InternalLayoutAdapter(id: id, child: child));
      }
    }
    return result;
  }

  void _onStateChange() {
    // Avoid rebuilding the entire tree on every animation tick.
    // Instead, we only update state. The Delegate listens to stateManager and relayouts.
    // The AnimatedPanels listen to stateManager and repaint.

    if (_lastConstraints == null) return;

    bool isAnyAnimating = false;

    for (final panel in _processedChildren) {
      if (panel is! InlinePanel) continue;

      final anim = _stateManager.getAnimationController(panel.id);
      final collapseAnim = _stateManager.getCollapseController(panel.id);

      final isAnimating =
          (anim != null && anim.isAnimating) ||
          (collapseAnim != null && collapseAnim.isAnimating);

      if (isAnimating) isAnyAnimating = true;

            // We look for Fixed panels that are animating for stability locking
            final panelFlex = panel is InternalLayoutAdapter ? panel.flex : null;
            if (panelFlex != null) continue;
      
            final neighbor = _getStableNeighbor(panel);
            if (neighbor == null) continue;
            
            final neighborFlex = neighbor is InternalLayoutAdapter ? neighbor.flex : null;
            if (neighborFlex == null) continue;
      final neighborState = _stateManager.getState(neighbor.id);
      if (neighborState == null) continue;

      if (isAnimating) {
        // LOCK: If not already locked, lock it to current pixel size
        if (neighborState.fixedPixelSizeOverride == null) {
          final currentFlex = neighborState.size;

          // Calculate FRESH ratio
          final layoutData = _engine.createLayoutData(
            uniquePanelConfigs: {for (var p in _processedChildren) p.id: p},
            config: widget.style ?? const PanelStyle(),
            stateManager: _stateManager,
          );
          final ratio = _engine.calculatePixelToFlexRatio(
            layoutData: layoutData,
            constraints: _lastConstraints!,
            axis: _cachedAxis,
            config: widget.style ?? const PanelStyle(),
          );

          if (ratio > 0) {
            final currentPixels = currentFlex / ratio;
            _stateManager.setFixedSizeOverride(neighbor.id, currentPixels);
          }
        }
      } else {
        // UNLOCK: If locked, calculate new flex and unlock
        if (neighborState.fixedPixelSizeOverride != null) {
          final override = neighborState.fixedPixelSizeOverride!;

          final layoutData = _engine.createLayoutData(
            uniquePanelConfigs: {for (var p in _processedChildren) p.id: p},
            config: widget.style ?? const PanelStyle(),
            stateManager: _stateManager,
          );

          final newFlex = _engine.calculateNewFlexForUnlockedPanel(
            layoutData: layoutData,
            targetPanelId: neighbor.id,
            targetPixels: override,
            constraints: _lastConstraints!,
            axis: _cachedAxis,
            config: widget.style ?? const PanelStyle(),
          );

          _stateManager.clearFixedSizeOverride(neighbor.id, newFlex);
        }
      }
    }

    // Check if animation just finished
    if (_wasAnimating && !isAnyAnimating) {
      // Animation finished. Rebuild to clean up (e.g. remove handles for hidden panels).
      setState(() {});
    }
    _wasAnimating = isAnyAnimating;
  }

  InlinePanel? _getStableNeighbor(InlinePanel sourcePanel) {
    final panels = _processedChildren.whereType<InlinePanel>().toList();
    final index = panels.indexWhere((p) => p.id == sourcePanel.id);
    if (index == -1) return null;

    // Anchor Right/Bottom -> Stable is Right/Bottom (Next)
    // Anchor Left/Top -> Stable is Left/Top (Prev)
    final isAnchorEnd =
        sourcePanel.anchor == PanelAnchor.right ||
        sourcePanel.anchor == PanelAnchor.bottom;

    if (isAnchorEnd) {
      // Look for Next
      if (index < panels.length - 1) return panels[index + 1];
    } else {
      // Look for Prev
      if (index > 0) return panels[index - 1];
    }
    return null;
  }

  @override
  void didUpdateWidget(PanelLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    _processedChildren = _processChildren(widget.children);
    _cachedAxis = _engine.validateAndComputeAxis(_processedChildren);
    if (widget.controller != oldWidget.controller) {
      if (oldWidget.controller == null) {
        _internalController?.detach();
        _internalController = null;
      } else {
        oldWidget.controller!.detach();
      }

      if (widget.controller == null) {
        _internalController = PanelLayoutController();
      }
      _effectiveController.attach(this);
    }
    _reconcileState();
  }

  @override
  void dispose() {
    _effectiveController.detach();
    _internalController?.dispose();
    _stateManager.removeListener(_onStateChange);
    _stateManager.dispose();
    super.dispose();
  }

  // --- Interface Implementation ---

  @override
  void toggleVisible(PanelId id) {
    final state = _stateManager.getState(id);
    if (state != null) {
      _stateManager.setVisible(id, !state.visible);
    }
  }

  @override
  void toggleCollapsed(PanelId id) {
    final state = _stateManager.getState(id);
    if (state != null) {
      _stateManager.setCollapsed(id, !state.collapsed);
    }
  }

  @override
  void setVisible(PanelId id, bool visible) {
    _stateManager.setVisible(id, visible);
  }

  @override
  void setCollapsed(PanelId id, bool collapsed) {
    _stateManager.setCollapsed(id, collapsed);
  }

  /// Ensures internal state maps match the current list of children.
  void _reconcileState() {
    final config = widget.style ?? const PanelStyle();
    _stateManager.reconcile(_processedChildren, config, this);
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.style ?? const PanelStyle();
    final axis = _cachedAxis;
    final uniquePanelConfigs = <PanelId, BasePanel>{};
    for (final panel in _processedChildren) {
      uniquePanelConfigs[panel.id] = panel;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        _lastConstraints = constraints;

        // 1. Prepare data for the layout delegate
        final layoutData = _engine.createLayoutData(
          uniquePanelConfigs: uniquePanelConfigs,
          config: config,
          stateManager: _stateManager,
        );

        // 2. Calculate Pixel-to-Flex Ratio
        final pixelToFlexRatio = _engine.calculatePixelToFlexRatio(
          layoutData: layoutData,
          constraints: constraints,
          axis: axis,
          config: config,
        );

        // 3. Build Layout Children
        final children = <Widget>[
          ..._buildPanelWidgets(uniquePanelConfigs),
          ..._buildResizeHandles(
            layoutData: layoutData,
            axis: axis,
            pixelToFlexRatio: pixelToFlexRatio,
          ),
        ];

        final sortedChildren = _engine.sortChildren(
          unsorted: children,
          configs: uniquePanelConfigs,
        );

        return PanelScope(
          controller: _effectiveController,
          child: PanelConfigurationScope(
            style: config,
            child: CustomMultiChildLayout(
              delegate: PanelLayoutDelegate(
                stateManager: _stateManager,
                configs: uniquePanelConfigs,
                style: config,
                engine: _engine,
                axis: axis,
                textDirection: Directionality.of(context),
              ),
              children: sortedChildren,
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildPanelWidgets(Map<PanelId, BasePanel> uniquePanelConfigs) {
    final widgets = <Widget>[];
    for (final panel in uniquePanelConfigs.values) {
      // Wrap in ListenableBuilder to isolate updates from parent rebuilds
      final childWidget = ListenableBuilder(
        listenable: _stateManager,
        builder: (context, _) {
          final state = _stateManager.getState(panel.id)!;
          final factor = _stateManager.getAnimationController(panel.id)!.value;
          final collapseFactor = _stateManager
              .getCollapseController(panel.id)!
              .value;

          Widget panelWidget = AnimatedPanel(
            config: panel,
            state: state,
            factor: factor,
            collapseFactor: collapseFactor,
          );

          // If anchored to external link, wrap in Follower
          if (panel is OverlayPanel && panel.anchorLink != null) {
            panelWidget = CompositedTransformFollower(
              link: panel.anchorLink!,
              showWhenUnlinked: false,
              child: panelWidget,
            );
          }

          return PanelDataScope(
            state: state,
            config: panel,
            child: panelWidget,
          );
        },
      );

      widgets.add(LayoutId(id: panel.id, child: childWidget));
    }
    return widgets;
  }

  List<Widget> _buildResizeHandles({
    required List<PanelLayoutData> layoutData,
    required Axis axis,
    required double pixelToFlexRatio,
  }) {
    final widgets = <Widget>[];
    final dockedPanels = layoutData
        .where((d) => d.config is InlinePanel)
        .toList();

    for (var i = 0; i < dockedPanels.length - 1; i++) {
      final prev = dockedPanels[i];
      final next = dockedPanels[i + 1];

      // Handle visibility based on static state, but only remove if animation finished
      if (!prev.state.visible || !next.state.visible) {
        if (prev.visualFactor <= 0 || next.visualFactor <= 0) continue;
      }

      // Skip resize handle between two InternalLayoutAdapter panels (content fillers)
      if (prev.config is InternalLayoutAdapter &&
          next.config is InternalLayoutAdapter) {
        continue;
      }

      final handleId = HandleLayoutId(prev.config.id, next.config.id);

      widgets.add(
        LayoutId(
          id: handleId,
          child: PanelResizeHandle(
            axis: axis == Axis.horizontal ? Axis.vertical : Axis.horizontal,
            resizable: PanelResizing.canResize(
              prev.config as InlinePanel,
              next.config as InlinePanel,
            ),
            onDragUpdate: (delta) =>
                _handleResize(delta, prev, next, pixelToFlexRatio),
            onDragStart: widget.onResizeStart,
            onDragEnd: widget.onResizeEnd,
          ),
        ),
      );
    }
    return widgets;
  }

  void _handleResize(
    double delta,
    PanelLayoutData prevData,
    PanelLayoutData nextData,
    double pixelToFlexRatio,
  ) {
    // Calculate fresh ratio and data since we don't rebuild
    if (_lastConstraints == null) return;

    final config = widget.style ?? const PanelStyle();
    final layoutData = _engine.createLayoutData(
      uniquePanelConfigs: {for (var p in _processedChildren) p.id: p},
      config: config,
      stateManager: _stateManager,
    );

    final currentPixelToFlexRatio = _engine.calculatePixelToFlexRatio(
      layoutData: layoutData,
      constraints: _lastConstraints!,
      axis: _cachedAxis,
      config: config,
    );

    // Fetch the latest state to ensure we are accumulating deltas correctly
    final prevState = _stateManager.getState(prevData.config.id)!;
    final nextState = _stateManager.getState(nextData.config.id)!;

    final changes = PanelResizing.calculateResize(
      delta: delta,
      prevConfig: prevData.config as InlinePanel,
      prevState: prevState,
      prevCollapsedSize: prevData.collapsedSize,
      nextConfig: nextData.config as InlinePanel,
      nextState: nextState,
      nextCollapsedSize: nextData.collapsedSize,
      pixelToFlexRatio: currentPixelToFlexRatio,
    );

    for (final entry in changes.entries) {
      _stateManager.updateSize(entry.key, entry.value);
    }
  }
}
