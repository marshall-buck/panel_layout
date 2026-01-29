import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import '../models/panel_id.dart';
import '../widgets/panels/base_panel.dart';
import '../widgets/internal/internal_layout_adapter.dart';
import '../layout/panel_style.dart';
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
  final Map<PanelId, ValueNotifier<PanelRuntimeState>> _stateNotifiers = {};
  final Map<PanelId, AnimationController> _animationControllers = {};
  final Map<PanelId, AnimationController> _collapseControllers = {};

  /// Tracks which panels requested to preserve their layout state.
  final Set<PanelId> _preservedIds = {};

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

  /// Retrieves the state notifier for a panel.
  ValueNotifier<PanelRuntimeState>? getStateNotifier(PanelId id) =>
      _stateNotifiers[id];

  /// Ensures internal state maps match the current list of children.
  /// Adds missing states and removes orphaned ones.
  void reconcile(
    List<BasePanel> panels,
    PanelStyle config,
    TickerProvider vsync,
  ) {
    final currentIds = panels.map((p) => p.id).toSet();

    // Update preservation preferences for current panels
    for (final panel in panels) {
      if (panel.preserveLayoutState) {
        _preservedIds.add(panel.id);
      } else {
        _preservedIds.remove(panel.id);
      }
    }

    // Remove orphaned states and controllers
    // Only remove state if it's not preserved
    _panelStates.removeWhere(
      (id, _) {
        if (!currentIds.contains(id) && !_preservedIds.contains(id)) {
           _stateNotifiers[id]?.dispose();
           _stateNotifiers.remove(id);
           return true;
        }
        return false;
      },
    );

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
        final initialState = PanelRuntimeState(
          size: _getInitialSize(panel),
          visible: panel.initialVisible,
          collapsed: panel.initialCollapsed,
        );
        _panelStates[panel.id] = initialState;
        _stateNotifiers[panel.id] = ValueNotifier(initialState);
      }

      // Controllers are always recreated (they need vsync and are ephemeral)
      if (!_animationControllers.containsKey(panel.id)) {
        final state = _panelStates[panel.id]!;

        // Priority: Panel Override > Config > Default Constant
        final fade = panel.fadeDuration ?? config.fadeDuration;
        final slide = panel.sizeDuration ?? config.sizeDuration;
        final maxDuration = fade > slide ? fade : slide;
        final effectiveDuration = panel.animationDuration ?? maxDuration;

        final controller = AnimationController(
          vsync: vsync,
          duration: effectiveDuration,
          value: state.visible ? 1.0 : 0.0,
        );
        controller.addListener(notifyListeners);
        _animationControllers[panel.id] = controller;

        final collapseController = AnimationController(
          vsync: vsync,
          duration: effectiveDuration,
          value: state.collapsed ? 1.0 : 0.0,
        );
        collapseController.addListener(notifyListeners);
        _collapseControllers[panel.id] = collapseController;
      }
    }
  }

  double _getInitialSize(BasePanel panel) {
    if (panel is InternalLayoutAdapter) return panel.layoutWeight;
    if (panel.width != null) return panel.width!;
    if (panel.height != null) return panel.height!;
    return 0.0;
  }

  void _updateState(PanelId id, PanelRuntimeState newState) {
    _panelStates[id] = newState;
    _stateNotifiers[id]?.value = newState;
    notifyListeners();
  }

  void setVisible(PanelId id, bool visible) {
    final state = _panelStates[id];
    if (state != null && state.visible != visible) {
      _updateState(id, state.copyWith(visible: visible));
      _animatePanel(id, visible);
    }
  }

  void setCollapsed(PanelId id, bool collapsed) {
    final state = _panelStates[id];
    if (state != null && state.collapsed != collapsed) {
      _updateState(id, state.copyWith(collapsed: collapsed));
      _animateCollapse(id, collapsed);
    }
  }

  void updateSize(PanelId id, double size) {
    final state = _panelStates[id];
    if (state != null) {
      _updateState(id, state.copyWith(size: size));
    }
  }

  void setFixedSizeOverride(PanelId id, double size) {
    final state = _panelStates[id];
    if (state != null) {
      _updateState(id, state.copyWith(fixedPixelSizeOverride: size));
    }
  }

  void clearFixedSizeOverride(PanelId id, double newSize) {
    final state = _panelStates[id];
    if (state != null) {
      // Reconstruct to force null override
      _updateState(id, PanelRuntimeState(
        size: newSize,
        visible: state.visible,
        collapsed: state.collapsed,
        fixedPixelSizeOverride: null,
      ));
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
    for (final notifier in _stateNotifiers.values) {
      notifier.dispose();
    }
    super.dispose();
  }
}
