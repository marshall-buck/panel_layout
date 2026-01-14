import 'package:flutter/widgets.dart';

import '../constants.dart';
import '../models/panel_id.dart';
import '../models/panel_enums.dart';
import '../state/panel_runtime_state.dart';
import '../state/panel_scope.dart';
import '../state/panel_data_scope.dart';
import '../layout/layout_data.dart';
import '../layout/panel_layout_delegate.dart';
import '../controllers/panel_layout_controller.dart';
import 'base_panel.dart';
import 'panel_resize_handle.dart';
import 'animated_panel.dart';

/// The declarative orchestrator for the panel layout system.
///
/// [PanelLayout] manages a list of [BasePanel] children. It tracks their
/// ephemeral state (like dragged size or collapse state) and calculates
/// their layout using a custom delegate.
class PanelLayout extends StatefulWidget {
  /// Creates a declarative panel layout.
  const PanelLayout({
    required this.children,
    this.controller,
    this.axis = Axis.horizontal,
    this.onResizeStart,
    this.onResizeEnd,
    super.key,
  });

  /// The list of declarative panel configurations.
  ///
  /// These widgets should extend [BasePanel].
  final List<BasePanel> children;

  /// An optional controller to manipulate panel state programmatically.
  final PanelLayoutController? controller;

  /// The main axis of the layout.
  final Axis axis;

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
  /// Internal state for each panel, keyed by ID.
  final Map<PanelId, PanelRuntimeState> _panelStates = {};

  /// Animation controllers for each panel's visibility.
  final Map<PanelId, AnimationController> _animationControllers = {};

  /// Animation controllers for each panel's collapse state.
  final Map<PanelId, AnimationController> _collapseControllers = {};

  PanelLayoutController? _internalController;
  PanelLayoutController get _effectiveController =>
      widget.controller ?? _internalController!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _internalController = PanelLayoutController();
    }
    _reconcileState();
    _effectiveController.attach(this);
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
    for (final controller in _animationControllers.values) {
      controller.dispose();
    }
    for (final controller in _collapseControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  // --- Interface Implementation ---

  @override
  void toggleVisible(PanelId id) {
    if (_panelStates.containsKey(id)) {
      setVisible(id, !_panelStates[id]!.visible);
    }
  }

  @override
  void toggleCollapsed(PanelId id) {
    if (_panelStates.containsKey(id)) {
      setCollapsed(id, !_panelStates[id]!.collapsed);
    }
  }

  @override
  void setVisible(PanelId id, bool visible) {
    final state = _panelStates[id];
    if (state != null && state.visible != visible) {
      setState(() {
        _panelStates[id] = state.copyWith(visible: visible);
      });
      _animatePanel(id, visible);
    }
  }

  @override
  void setCollapsed(PanelId id, bool collapsed) {
    final state = _panelStates[id];
    if (state != null && state.collapsed != collapsed) {
      setState(() {
        _panelStates[id] = state.copyWith(collapsed: collapsed);
      });
      // Trigger collapse animation
      _animateCollapse(id, collapsed);
    }
  }

  void _animatePanel(PanelId id, bool visible) {
    final controller = _animationControllers[id];
    if (controller != null) {
      if (visible) {
        controller.forward();
      } else {
        controller.reverse();
      }
    }
  }

  void _animateCollapse(PanelId id, bool collapsed) {
    final controller = _collapseControllers[id];
    if (controller != null) {
      if (collapsed) {
        controller.forward();
      } else {
        controller.reverse();
      }
    }
  }

  void _reconcileState() {
    final currentIds = widget.children.map((p) => p.id).toSet();

    _panelStates.removeWhere((id, _) => !currentIds.contains(id));

    for (final id in _animationControllers.keys.toList()) {
      if (!currentIds.contains(id)) {
        _animationControllers[id]!.dispose();
        _animationControllers.remove(id);
      }
    }
    for (final id in _collapseControllers.keys.toList()) {
      if (!currentIds.contains(id)) {
        _collapseControllers[id]!.dispose();
        _collapseControllers.remove(id);
      }
    }

    for (final panel in widget.children) {
      if (!_panelStates.containsKey(panel.id)) {
        _panelStates[panel.id] = PanelRuntimeState(
          size: _getInitialSize(panel),
          visible: panel.initialVisible,
          collapsed: panel.initialCollapsed,
        );

        final controller = AnimationController(
          vsync: this,
          duration: panel.animationDuration ?? kDefaultAnimationDuration,
          value: panel.initialVisible ? 1.0 : 0.0,
        );
        controller.addListener(() => setState(() {}));
        _animationControllers[panel.id] = controller;

        final collapseController = AnimationController(
          vsync: this,
          duration: panel.animationDuration ?? kDefaultAnimationDuration,
          value: panel.initialCollapsed ? 1.0 : 0.0,
        );
        collapseController.addListener(() => setState(() {}));
        _collapseControllers[panel.id] = collapseController;
      }
    }
  }

  double _getInitialSize(BasePanel panel) {
    if (panel.flex != null) return panel.flex!;
    if (panel.width != null) return panel.width!;
    if (panel.height != null) return panel.height!;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final uniquePanelConfigs = <PanelId, BasePanel>{};
    for (final panel in widget.children) {
      uniquePanelConfigs[panel.id] = panel;
    }

    final layoutData = uniquePanelConfigs.values.map((config) {
      final state = _panelStates[config.id]!;
      final anim = _animationControllers[config.id]!;
      final collapseAnim = _collapseControllers[config.id]!;

      return PanelLayoutData(
        config: config,
        state: state,
        visualFactor: anim.value,
        collapseFactor: collapseAnim.value,
      );
    }).toList();

    final dockedPanels = layoutData
        .where((d) => d.config.mode == PanelMode.inline)
        .toList();

    final children = <Widget>[];

    // Add Panels
    for (final panel in uniquePanelConfigs.values) {
      final state = _panelStates[panel.id]!;
      final factor = _animationControllers[panel.id]!.value;

      Widget panelWidget = AnimatedPanel(
        config: panel,
        state: state,
        factor: factor,
        collapseFactor: _collapseControllers[panel.id]!.value,
      );

      // If anchored to external link, wrap in Follower
      if (panel.anchorLink != null) {
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
            axis: widget.axis == Axis.horizontal
                ? Axis.vertical
                : Axis.horizontal,
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
      child: CustomMultiChildLayout(
        delegate: PanelLayoutDelegate(
          panels: layoutData,
          axis: widget.axis,
          textDirection: Directionality.of(context),
        ),
        children: sortedChildren,
      ),
    );
  }

  List<Widget> _sortChildren(
    List<Widget> unsorted,
    Map<PanelId, BasePanel> configs,
  ) {
    final List<Widget> sorted = List.from(unsorted);
    sorted.sort((a, b) {
      final idA = (a as LayoutId).id;
      final idB = (b as LayoutId).id;

      int zA = 0;
      if (idA is PanelId) zA = configs[idA]?.zIndex ?? 0;

      int zB = 0;
      if (idB is PanelId) zB = configs[idB]?.zIndex ?? 0;

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
      final prev = _panelStates[prevData.config.id]!;
      final next = _panelStates[nextData.config.id]!;

      if (prevData.config.flex == null && prevData.config.resizable) {
        final newSize = (prev.size + delta).clamp(
          prevData.config.minSize ?? 0.0,
          prevData.config.maxSize ?? double.infinity,
        );
        _panelStates[prevData.config.id] = prev.copyWith(size: newSize);
        return;
      }

      if (nextData.config.flex == null && nextData.config.resizable) {
        final newSize = (next.size - delta).clamp(
          nextData.config.minSize ?? 0.0,
          nextData.config.maxSize ?? double.infinity,
        );
        _panelStates[nextData.config.id] = next.copyWith(size: newSize);
        return;
      }

      if (prevData.config.flex != null &&
          nextData.config.flex != null &&
          prevData.config.resizable &&
          nextData.config.resizable) {
        final w1 = prev.size;
        final w2 = next.size;

        const sensitivity = 0.01;
        _panelStates[prevData.config.id] = prev.copyWith(
          size: (w1 + delta * sensitivity).clamp(0.0, double.infinity),
        );
        _panelStates[nextData.config.id] = next.copyWith(
          size: (w2 - delta * sensitivity).clamp(0.0, double.infinity),
        );
        return;
      }
    });
  }
}
