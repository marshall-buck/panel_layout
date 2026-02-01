import 'package:flutter/widgets.dart';

import '../models/panel_enums.dart';
import '../models/panel_id.dart';
import '../models/resolved_panel.dart';
import '../state/panel_scope.dart';
import '../state/panel_state_manager.dart';
import '../models/panel_style.dart';
import '../layout/panel_area_delegate.dart';
import '../layout/panel_resizing.dart';
import '../layout/panel_layout_engine.dart';
import '../controllers/panel_area_controller.dart';
import 'widgets.dart';
import 'animation/animated_panel.dart';
import 'internal/panel_resize_handle.dart';
import 'internal/internal_layout_adapter.dart';

/// The root widget of the panel system.
///
/// [PanelArea] is a declarative widget that manages a list of [BasePanel] children,
/// orchestrating their layout, sizing, and animations.
///
/// ### Features:
/// - **Declarative Configuration**: Define panels as a list of [InlinePanel] and [OverlayPanel] widgets.
/// - **State Management**: Internally tracks panel sizes (from user resizing) and visibility/collapse states.
/// - **Controller**: Optionally accepts a [PanelAreaController] for external programmatic control.
/// - **Animations**: Automatically handles size and opacity transitions when panel state changes.
/// - **Resizing**: Renders [PanelResizeHandle]s between adjacent resizable inline panels.
///
/// ### Example:
/// ```dart
/// PanelArea(
///   controller: myController,
///   children: [
///     InlinePanel(
///       id: PanelId('sidebar'),
///       width: 250,
///       child: Sidebar(),
///     ),
///     // Standard widget wrapped automatically (layoutWeight: 1)
///     MainContent(),
///   ],
/// )
/// ```
class PanelArea extends StatefulWidget {
  /// Creates a declarative panel area.
  const PanelArea({
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
  /// - Standard [Widget]s are automatically wrapped in an internal adapter that fills remaining space (layoutWeight=1).
  final List<Widget> children;

  /// An optional controller to manipulate panel state programmatically.
  ///
  /// If provided, you must dispose of it yourself. If not provided,
  /// the layout creates and manages its own internal controller.
  final PanelAreaController? controller;

  /// The configuration for styling and behavior.
  final PanelStyle? style;

  /// Optional callback called when a user begins dragging a resize handle.
  final VoidCallback? onResizeStart;

  /// Optional callback called when a user finishes dragging a resize handle.
  final VoidCallback? onResizeEnd;

  /// Retrieves the [PanelAreaController] from the closest [PanelScope] ancestor.
  static PanelAreaController of(BuildContext context) {
    return PanelScope.of(context);
  }

  @override
  State<PanelArea> createState() => _PanelLayoutState();
}

class _PanelLayoutState extends State<PanelArea>
    with TickerProviderStateMixin
    implements PanelLayoutStateInterface {
  late final PanelStateManager _stateManager;
  late Axis _cachedAxis;
  static const _engine = PanelLayoutEngine();

  PanelAreaController? _internalController;
  PanelAreaController get _effectiveController =>
      widget.controller ?? _internalController!;

  late List<BasePanel> _processedChildren;

  // Track previous frame's constraints/ratio for calculations
  BoxConstraints? _lastConstraints;

  // Track animation status to trigger locking/unlocking only on status changes
  final Map<PanelId, AnimationStatus> _lastAnimationStatus = {};

  @override
  void initState() {
    super.initState();
    _processedChildren = _processChildren(widget.children);
    _cachedAxis = _engine.validateAndComputeAxis(_processedChildren);
    _stateManager = PanelStateManager();
    _stateManager.addListener(_onStateChange);

    if (widget.controller == null) {
      _internalController = PanelAreaController();
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
    if (_lastConstraints == null) return;
    bool shouldRebuild = false;

    for (final panel in _processedChildren) {
      if (panel is! InlinePanel) continue;

      final anim = _stateManager.getAnimationController(panel.id);
      final collapseAnim = _stateManager.getCollapseController(panel.id);

      // We combine status: if either is animating, we consider it animating.
      // Prioritize the one that is active.
      final AnimationStatus status;
      if (anim != null &&
          (anim.isAnimating ||
              anim.status == AnimationStatus.forward ||
              anim.status == AnimationStatus.reverse)) {
        status = anim.status;
      } else if (collapseAnim != null &&
          (collapseAnim.isAnimating ||
              collapseAnim.status == AnimationStatus.forward ||
              collapseAnim.status == AnimationStatus.reverse)) {
        status = collapseAnim.status;
      } else {
        // Default to dismissed if neither (or completed/dismissed check)
        status = anim?.status ?? AnimationStatus.dismissed;
      }

      final lastStatus =
          _lastAnimationStatus[panel.id] ?? AnimationStatus.dismissed;

      if (status != lastStatus) {
        _lastAnimationStatus[panel.id] = status;

        final isStarting =
            (status == AnimationStatus.forward ||
                status == AnimationStatus.reverse) &&
            (lastStatus == AnimationStatus.completed ||
                lastStatus == AnimationStatus.dismissed);

        final isEnding =
            (status == AnimationStatus.completed ||
                status == AnimationStatus.dismissed) &&
            (lastStatus == AnimationStatus.forward ||
                lastStatus == AnimationStatus.reverse);

        if (isStarting) {
          _lockNeighbor(panel);
        }

        if (isEnding) {
          _unlockNeighbor(panel);
          shouldRebuild = true; // Rebuild to remove/add handles
        }
      }
    }

    if (shouldRebuild) {
      setState(() {});
    }
  }

  void _lockNeighbor(InlinePanel panel) {
    // LOCK: Lock neighbor to current pixel size
    final neighbor = _getStableNeighbor(panel);
    if (neighbor == null) return;

    // If neighbor has width/height, it's fixed.
    if (neighbor.width != null || neighbor.height != null) return;

    final neighborState = _stateManager.getState(neighbor.id);
    if (neighborState == null || neighborState.fixedPixelSizeOverride != null) {
      return;
    }

    final currentWeight = neighborState.size;

    // Calculate FRESH ratio
    final layoutData = _engine.createLayoutData(
      uniquePanelConfigs: {for (var p in _processedChildren) p.id: p},
      config: widget.style ?? const PanelStyle(),
      stateManager: _stateManager,
    );
    final ratio = _engine.calculatePixelToWeightRatio(
      layoutData: layoutData,
      constraints: _lastConstraints!,
      axis: _cachedAxis,
      config: widget.style ?? const PanelStyle(),
    );

    if (ratio > 0) {
      final currentPixels = currentWeight / ratio;
      _stateManager.setFixedSizeOverride(neighbor.id, currentPixels);
    }
  }

  void _unlockNeighbor(InlinePanel panel) {
    final neighbor = _getStableNeighbor(panel);
    if (neighbor == null) return;

    final neighborState = _stateManager.getState(neighbor.id);
    if (neighborState == null || neighborState.fixedPixelSizeOverride == null) {
      return;
    }

    final override = neighborState.fixedPixelSizeOverride!;

    final layoutData = _engine.createLayoutData(
      uniquePanelConfigs: {for (var p in _processedChildren) p.id: p},
      config: widget.style ?? const PanelStyle(),
      stateManager: _stateManager,
    );

    final newWeight = _engine.calculateNewWeightForUnlockedPanel(
      layoutData: layoutData,
      targetPanelId: neighbor.id,
      targetPixels: override,
      constraints: _lastConstraints!,
      axis: _cachedAxis,
      config: widget.style ?? const PanelStyle(),
    );

    _stateManager.clearFixedSizeOverride(neighbor.id, newWeight);
  }

  InlinePanel? _getStableNeighbor(InlinePanel sourcePanel) {
    final panels = _processedChildren.whereType<InlinePanel>().toList();
    final index = panels.indexWhere((p) => p.id == sourcePanel.id);
    if (index == -1) return null;

    final isAnchorEnd =
        sourcePanel.anchor == PanelAnchor.right ||
        sourcePanel.anchor == PanelAnchor.bottom;

    if (isAnchorEnd) {
      // Anchor Right/Bottom -> Neighbor is Next (Right/Bottom)
      if (index < panels.length - 1) return panels[index + 1];
    } else {
      // Anchor Left/Top -> Neighbor is Prev (Left/Top)
      if (index > 0) return panels[index - 1];
    }
    return null;
  }

  @override
  void didUpdateWidget(PanelArea oldWidget) {
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
        _internalController = PanelAreaController();
      }
      _effectiveController.attach(this);
    }
    _reconcileState();
  }

  @override
  void dispose() {
    _effectiveController.detach();
    _internalController?.dispose();
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

  @override
  void updateSize(PanelId id, double size) {
    _stateManager.updateSize(id, size);
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

        // 1. Build Layout Children
        // We no longer calculate layoutData here to avoid redundant work.
        // Handles are created for all valid pairs; the delegate handles visibility/layout.
        final children = <Widget>[
          ..._buildPanelWidgets(uniquePanelConfigs),
          ..._buildResizeHandles(
            panels: _processedChildren,
            axis: axis,
            uniqueConfigs: uniquePanelConfigs,
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
              delegate: PanelAreaDelegate(
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
      // OPTIMIZATION: Removed global ListenableBuilder.
      // AnimatedPanel now listens internally to specific animations and state changes.

      final state = _stateManager.getState(panel.id)!;
      final stateNotifier = _stateManager.getStateNotifier(panel.id)!;
      final visibilityAnim = _stateManager.getAnimationController(panel.id)!;
      final collapseAnim = _stateManager.getCollapseController(panel.id)!;

      Widget panelWidget = AnimatedPanel(
        config: panel,
        initialState: state,
        stateNotifier: stateNotifier,
        visibilityAnimation: visibilityAnim,
        collapseAnimation: collapseAnim,
      );

      // If anchored to external link, wrap in Follower
      if (panel is OverlayPanel && panel.anchorLink != null) {
        panelWidget = CompositedTransformFollower(
          link: panel.anchorLink!,
          showWhenUnlinked: false,
          child: panelWidget,
        );
      }

      widgets.add(LayoutId(id: panel.id, child: panelWidget));
    }
    return widgets;
  }

  List<Widget> _buildResizeHandles({
    required List<BasePanel> panels,
    required Axis axis,
    required Map<PanelId, BasePanel> uniqueConfigs,
  }) {
    final widgets = <Widget>[];
    // Use unique configs to ensure we match the layout engine's list and avoid duplicate IDs
    final dockedPanels = uniqueConfigs.values.whereType<InlinePanel>().toList();

    for (var i = 0; i < dockedPanels.length - 1; i++) {
      final prev = dockedPanels[i];
      final next = dockedPanels[i + 1];

      // Skip resize handle between two InternalLayoutAdapter panels (content fillers)
      if (prev is InternalLayoutAdapter && next is InternalLayoutAdapter) {
        continue;
      }

      // Check visibility/animation status to decide if handle should be built.
      // We do this here to satisfy tests that expect handles to be removed from the tree.
      // This is a cheap lookup compared to full layout calculation.
      final prevState = _stateManager.getState(prev.id);
      final nextState = _stateManager.getState(next.id);
      _stateManager.getAnimationController(prev.id);
      _stateManager.getAnimationController(next.id);

      final prevVisible = prevState?.visible ?? true;
      final nextVisible = nextState?.visible ?? true;

      if (!prevVisible || !nextVisible) {
        continue;
      }

      final handleId = HandleLayoutId(prev.id, next.id);

      widgets.add(
        LayoutId(
          id: handleId,
          child: PanelResizeHandle(
            axis: axis == Axis.horizontal ? Axis.vertical : Axis.horizontal,
            resizable: PanelResizing.canResize(prev, next),
            onDragUpdate: (delta) {
              final prevState = _stateManager.getState(prev.id)!;
              final prevAnim = _stateManager.getAnimationController(prev.id)!;
              final prevCollapse = _stateManager.getCollapseController(
                prev.id,
              )!;

              final nextState = _stateManager.getState(next.id)!;
              final nextAnim = _stateManager.getAnimationController(next.id)!;
              final nextCollapse = _stateManager.getCollapseController(
                next.id,
              )!;

              final config = widget.style ?? const PanelStyle();

              double getCollapsedSize(InlinePanel p) {
                final iconSize = p.iconSize ?? config.iconSize;
                return iconSize + (p.railPadding ?? config.railPadding);
              }

              final prevResolved = ResolvedPanel(
                config: prev,
                state: prevState,
                visualFactor: prevAnim.value,
                collapseFactor: prevCollapse.value,
                collapsedSize: getCollapsedSize(prev),
              );
              final nextResolved = ResolvedPanel(
                config: next,
                state: nextState,
                visualFactor: nextAnim.value,
                collapseFactor: nextCollapse.value,
                collapsedSize: getCollapsedSize(next),
              );

              _handleResize(delta, prevResolved, nextResolved);
            },
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
    ResolvedPanel prevData,
    ResolvedPanel nextData,
  ) {
    // Calculate fresh ratio and data since we don't rebuild
    if (_lastConstraints == null) return;

    final config = widget.style ?? const PanelStyle();
    final layoutData = _engine.createLayoutData(
      uniquePanelConfigs: {for (var p in _processedChildren) p.id: p},
      config: config,
      stateManager: _stateManager,
    );

    final currentPixelToWeightRatio = _engine.calculatePixelToWeightRatio(
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
      pixelToWeightRatio: currentPixelToWeightRatio,
    );

    for (final entry in changes.entries) {
      _stateManager.updateSize(entry.key, entry.value);
    }
  }
}
