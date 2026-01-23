import 'package:flutter/widgets.dart';

import '../models/panel_enums.dart';
import '../models/panel_id.dart';
import '../state/panel_scope.dart';
import '../state/panel_data_scope.dart';
import '../state/panel_state_manager.dart';
import '../layout/panel_layout_config.dart';
import '../layout/layout_data.dart';
import '../layout/panel_layout_delegate.dart';
import '../layout/panel_resizing.dart';
import '../controllers/panel_layout_controller.dart';
import 'widgets.dart';
import 'animation/animated_panel.dart';
import 'internal/panel_resize_handle.dart';

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
    this.config,
    this.onResizeStart,
    this.onResizeEnd,
    super.key,
  });

  /// The list of declarative panel configurations.
  ///
  /// These widgets should extend [BasePanel] (typically [InlinePanel] or [OverlayPanel]).
  /// The order of [InlinePanel]s in this list determines their layout order.
  final List<BasePanel> children;

  /// An optional controller to manipulate panel state programmatically.
  ///
  /// If provided, you must dispose of it yourself. If not provided,
  /// the layout creates and manages its own internal controller.
  final PanelLayoutController? controller;

  /// The configuration for styling and behavior.
  final PanelLayoutConfig? config;

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

  PanelLayoutController? _internalController;
  PanelLayoutController get _effectiveController =>
      widget.controller ?? _internalController!;

  @override
  void initState() {
    super.initState();
    _stateManager = PanelStateManager();
    _stateManager.addListener(_onStateChange);
    if (widget.controller == null) {
      _internalController = PanelLayoutController();
    }
    _reconcileState();
    _effectiveController.attach(this);
  }

  void _onStateChange() {
    setState(() {});
  }

  @override
  void didUpdateWidget(PanelLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
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
    final config = widget.config ?? const PanelLayoutConfig();
    _stateManager.reconcile(widget.children, config, this);
  }

  /// Infers the axis from the first [InlinePanel] found in [children].
  ///
  /// Validates that all [InlinePanel]s share the same axis.
  /// Defaults to [Axis.horizontal] if no inline panels are present.
  Axis _computeAxis(List<BasePanel> children) {
    Axis? axis;
    for (final child in children) {
      if (child is InlinePanel && child.anchor != null) {
        final childAxis =
            (child.anchor == PanelAnchor.left ||
                child.anchor == PanelAnchor.right)
            ? Axis.horizontal
            : Axis.vertical;

        if (axis == null) {
          axis = childAxis;
        } else if (axis != childAxis) {
          throw FlutterError(
            'PanelLayout contains InlinePanels with conflicting axes. '
            'Found both Horizontal (Left/Right) and Vertical (Top/Bottom) anchors. '
            'InlinePanels in a single PanelLayout must share the same axis.',
          );
        }
      }
    }
    return axis ?? Axis.horizontal;
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config ?? const PanelLayoutConfig();
    final axis = _computeAxis(widget.children);
    final uniquePanelConfigs = <PanelId, BasePanel>{};
    for (final panel in widget.children) {
      uniquePanelConfigs[panel.id] = panel;
    }

    // Prepare data for the layout delegate
    final layoutData = uniquePanelConfigs.values.map((panelConfig) {
      final state = _stateManager.getState(panelConfig.id)!;
      final anim = _stateManager.getAnimationController(panelConfig.id)!;
      final collapseAnim = _stateManager.getCollapseController(panelConfig.id)!;

      double collapsedSize = 0.0;
      if (panelConfig is InlinePanel) {
        final iconSize = panelConfig.iconSize ?? config.iconSize;
        collapsedSize =
            iconSize + (panelConfig.railPadding ?? config.railPadding);
      }

      return PanelLayoutData(
        config: panelConfig,
        state: state,
        visualFactor: anim.value,
        collapseFactor: collapseAnim.value,
        collapsedSize: collapsedSize,
      );
    }).toList();

    final dockedPanels = layoutData
        .where((d) => d.config is InlinePanel)
        .toList();

    final children = <Widget>[];

    // Add Panel Widgets
    for (final panel in uniquePanelConfigs.values) {
      final state = _stateManager.getState(panel.id)!;
      final factor = _stateManager.getAnimationController(panel.id)!.value;

      Widget panelWidget = AnimatedPanel(
        config: panel,
        state: state,
        factor: factor,
        collapseFactor: _stateManager.getCollapseController(panel.id)!.value,
      );

      // If anchored to external link, wrap in Follower
      if (panel is OverlayPanel && panel.anchorLink != null) {
        panelWidget = CompositedTransformFollower(
          link: panel.anchorLink!,
          showWhenUnlinked: false,
          child: panelWidget,
        );
      }

      children.add(
        LayoutId(
          id: panel.id,
          child: PanelDataScope(
            state: state,
            config: panel,
            child: panelWidget,
          ),
        ),
      );
    }

    // Add Resize Handles
    for (var i = 0; i < dockedPanels.length - 1; i++) {
      final prev = dockedPanels[i];
      final next = dockedPanels[i + 1];

      // Handle visibility based on static state, but only remove if animation finished
      if (!prev.state.visible || !next.state.visible) {
        if (prev.visualFactor <= 0 || next.visualFactor <= 0) continue;
      }

      final handleId = HandleLayoutId(prev.config.id, next.config.id);

      children.add(
        LayoutId(
          id: handleId,
          child: PanelResizeHandle(
            axis: axis == Axis.horizontal ? Axis.vertical : Axis.horizontal,
            onDragUpdate: (delta) => _handleResize(delta, prev, next),
            onDragStart: widget.onResizeStart,
            onDragEnd: widget.onResizeEnd,
          ),
        ),
      );
    }

    final sortedChildren = _sortChildren(children, uniquePanelConfigs);

    return PanelScope(
      controller: _effectiveController,
      child: PanelConfigurationScope(
        config: config,
        child: CustomMultiChildLayout(
          delegate: PanelLayoutDelegate(
            panels: layoutData,
            axis: axis,
            textDirection: Directionality.of(context),
          ),
          children: sortedChildren,
        ),
      ),
    );
  }

  /// Sorts children to ensure correct painting order (z-index).
  List<Widget> _sortChildren(
    List<Widget> unsorted,
    Map<PanelId, BasePanel> configs,
  ) {
    final List<Widget> sorted = List.from(unsorted);
    sorted.sort((a, b) {
      final idA = (a as LayoutId).id;
      final idB = (b as LayoutId).id;

      int zA = 0;
      if (idA is PanelId) {
        final config = configs[idA];
        if (config is OverlayPanel) zA = config.zIndex;
      }

      int zB = 0;
      if (idB is PanelId) {
        final config = configs[idB];
        if (config is OverlayPanel) zB = config.zIndex;
      }

      if (zA != zB) return zA.compareTo(zB);

      return unsorted.indexOf(a).compareTo(unsorted.indexOf(b));
    });

    return sorted;
  }

  void _handleResize(
    double delta,
    PanelLayoutData prevData,
    PanelLayoutData nextData,
  ) {
    setState(() {
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
      );

      for (final entry in changes.entries) {
        _stateManager.updateSize(entry.key, entry.value);
      }
    });
  }
}
