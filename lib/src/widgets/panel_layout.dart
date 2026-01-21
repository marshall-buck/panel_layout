import 'package:flutter/widgets.dart';

import '../models/panel_id.dart';
import '../state/panel_runtime_state.dart';
import '../state/panel_scope.dart';
import '../state/panel_data_scope.dart';
import '../layout/panel_layout_config.dart';
import '../layout/layout_data.dart';
import '../layout/panel_layout_delegate.dart';
import '../controllers/panel_layout_controller.dart';
import 'widgets.dart';
import 'animated_panel.dart';
import 'panel_resize_handle.dart';

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
    this.axis = Axis.horizontal,
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

  /// The main axis of the layout.
  ///
  /// - [Axis.horizontal]: Panels are laid out in a row (Left-to-Right).
  /// - [Axis.vertical]: Panels are laid out in a column (Top-to-Bottom).
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
  /// This persists the "runtime" values like current width (if resized) or visibility.
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

  /// Ensures internal state maps match the current list of children.
  /// Adds missing states and removes orphaned ones.
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

    // Default durations (we'll fetch from config if available in build, but here we might need defaults)
    // Actually, we can use kDefault constants for reconciliation if config isn't available,
    // or just use defaults. PanelLayoutConfig defaults match constants.
    // However, if the user provided a config with *different* durations, we should try to use them.
    // But config is a widget property. We can access `widget.config` here.

    final config = widget.config ?? const PanelLayoutConfig();

    for (final panel in widget.children) {
      if (!_panelStates.containsKey(panel.id)) {
        _panelStates[panel.id] = PanelRuntimeState(
          size: _getInitialSize(panel),
          visible: panel.initialVisible,
          collapsed: panel.initialCollapsed,
        );

        // Priority: Panel Override > Config > Default Constant
        final fade = panel.fadeDuration ?? config.fadeDuration;
        final slide = panel.sizeDuration ?? config.sizeDuration;
        final maxDuration = fade > slide ? fade : slide;
        final effectiveDuration = panel.animationDuration ?? maxDuration;

        final controller = AnimationController(
          vsync: this,
          duration: effectiveDuration,
          value: panel.initialVisible ? 1.0 : 0.0,
        );
        controller.addListener(() => setState(() {}));
        _animationControllers[panel.id] = controller;

        final collapseController = AnimationController(
          vsync: this,
          duration: effectiveDuration,
          value: panel.initialCollapsed ? 1.0 : 0.0,
        );
        collapseController.addListener(() => setState(() {}));
        _collapseControllers[panel.id] = collapseController;
      }
    }
  }

  double _getInitialSize(BasePanel panel) {
    if (panel is InlinePanel && panel.flex != null) return panel.flex!;
    if (panel.width != null) return panel.width!;
    if (panel.height != null) return panel.height!;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final config = widget.config ?? const PanelLayoutConfig();
    final uniquePanelConfigs = <PanelId, BasePanel>{};
    for (final panel in widget.children) {
      uniquePanelConfigs[panel.id] = panel;
    }

    // Prepare data for the layout delegate
    final layoutData = uniquePanelConfigs.values.map((panelConfig) {
      final state = _panelStates[panelConfig.id]!;
      final anim = _animationControllers[panelConfig.id]!;
      final collapseAnim = _collapseControllers[panelConfig.id]!;

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
      final state = _panelStates[panel.id]!;
      final factor = _animationControllers[panel.id]!.value;

      Widget panelWidget = AnimatedPanel(
        config: panel,
        state: state,
        factor: factor,
        collapseFactor: _collapseControllers[panel.id]!.value,
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
      child: PanelConfigurationScope(
        config: config,
        child: CustomMultiChildLayout(
          delegate: PanelLayoutDelegate(
            panels: layoutData,
            axis: widget.axis,
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
      final prev = _panelStates[prevData.config.id]!;
      final next = _panelStates[nextData.config.id]!;

      // We only resize inline panels, so safe to cast
      final prevConfig = prevData.config as InlinePanel;
      final nextConfig = nextData.config as InlinePanel;

      // Case 1: Prev is fixed, Next is whatever. Resize Prev.
      if (prevConfig.flex == null && prevConfig.resizable) {
        final newSize = (prev.size + delta).clamp(
          prevConfig.minSize ?? 0.0,
          prevConfig.maxSize ?? double.infinity,
        );
        _panelStates[prevConfig.id] = prev.copyWith(size: newSize);
        return;
      }

      // Case 2: Prev is flex (or not resizable), Next is fixed. Resize Next (inverse).
      if (nextConfig.flex == null && nextConfig.resizable) {
        final newSize = (next.size - delta).clamp(
          nextConfig.minSize ?? 0.0,
          nextConfig.maxSize ?? double.infinity,
        );
        _panelStates[nextConfig.id] = next.copyWith(size: newSize);
        return;
      }

      // Case 3: Both are flexible. Adjust flex weights.
      if (prevConfig.flex != null &&
          nextConfig.flex != null &&
          prevConfig.resizable &&
          nextConfig.resizable) {
        final w1 = prev.size;
        final w2 = next.size;

        const sensitivity = 0.01;
        _panelStates[prevConfig.id] = prev.copyWith(
          size: (w1 + delta * sensitivity).clamp(0.0, double.infinity),
        );
        _panelStates[nextConfig.id] = next.copyWith(
          size: (w2 - delta * sensitivity).clamp(0.0, double.infinity),
        );
        return;
      }
    });
  }
}
