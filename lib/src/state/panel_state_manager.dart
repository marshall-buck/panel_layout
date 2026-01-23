import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import '../models/panel_id.dart';
import '../widgets/panels/base_panel.dart';
import '../widgets/panels/inline_panel.dart';
import '../layout/panel_layout_config.dart';
import 'panel_runtime_state.dart';

/// Manages the runtime state and animations of panels.
///
/// This class acts as the source of truth for:
/// 1. [PanelRuntimeState] (size, visibility, collapse status).
/// 2. [AnimationController]s for visibility and collapse transitions.
///
/// It notifies listeners when any state changes or animation ticks occur.
@internal
class PanelStateManager extends ChangeNotifier {
  final Map<PanelId, PanelRuntimeState> _panelStates = {};
  final Map<PanelId, AnimationController> _animationControllers = {};
  final Map<PanelId, AnimationController> _collapseControllers = {};

  /// Read-only access to panel states.
  Map<PanelId, PanelRuntimeState> get panelStates =>
      Map.unmodifiable(_panelStates);

  /// Retrieves the visibility animation controller for a panel.
  AnimationController? getAnimationController(PanelId id) =>
      _animationControllers[id];

  /// Retrieves the collapse animation controller for a panel.
  AnimationController? getCollapseController(PanelId id) =>
      _collapseControllers[id];

  /// Retrieves the runtime state for a panel.
  PanelRuntimeState? getState(PanelId id) => _panelStates[id];

  /// Ensures internal state maps match the current list of children.
  /// Adds missing states and removes orphaned ones.
  void reconcile(
    List<BasePanel> panels,
    PanelLayoutConfig config,
    TickerProvider vsync,
  ) {
    final currentIds = panels.map((p) => p.id).toSet();

    // Remove orphaned states and controllers
    _panelStates.removeWhere((id, _) => !currentIds.contains(id));

    _animationControllers.removeWhere((id, controller) {
      if (!currentIds.contains(id)) {
        controller.dispose();
        return true;
      }
      return false;
    });

    _collapseControllers.removeWhere((id, controller) {
      if (!currentIds.contains(id)) {
        controller.dispose();
        return true;
      }
      return false;
    });

    // Add new states and controllers
    for (final panel in panels) {
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
          vsync: vsync,
          duration: effectiveDuration,
          value: panel.initialVisible ? 1.0 : 0.0,
        );
        controller.addListener(notifyListeners);
        _animationControllers[panel.id] = controller;

        final collapseController = AnimationController(
          vsync: vsync,
          duration: effectiveDuration,
          value: panel.initialCollapsed ? 1.0 : 0.0,
        );
        collapseController.addListener(notifyListeners);
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

  void setVisible(PanelId id, bool visible) {
    final state = _panelStates[id];
    if (state != null && state.visible != visible) {
      _panelStates[id] = state.copyWith(visible: visible);
      _animatePanel(id, visible);
      notifyListeners();
    }
  }

  void setCollapsed(PanelId id, bool collapsed) {
    final state = _panelStates[id];
    if (state != null && state.collapsed != collapsed) {
      _panelStates[id] = state.copyWith(collapsed: collapsed);
      _animateCollapse(id, collapsed);
      notifyListeners();
    }
  }

  void updateSize(PanelId id, double size) {
    final state = _panelStates[id];
    if (state != null) {
      _panelStates[id] = state.copyWith(size: size);
      notifyListeners();
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

  @override
  void dispose() {
    for (final controller in _animationControllers.values) {
      controller.dispose();
    }
    for (final controller in _collapseControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
