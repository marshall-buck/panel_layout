import 'package:flutter/foundation.dart';

import 'panel_controller.dart';
import 'panel_data.dart';

/// The central registry and orchestrator for all [PanelController]s in the application.
///
/// The [LayoutController] maintains a map of all registered panels, allowing different
/// parts of the application to look up and modify panel state.
///
/// It extends [ChangeNotifier] to notify listeners when panels are registered or removed.
class LayoutController extends ChangeNotifier {
  final Map<PanelId, PanelController> _panels = {};

  /// Registers a panel with the controller.
  ///
  /// If a panel with the same [id] already exists, it is returned directly.
  /// Otherwise, a new [PanelController] is created and stored.
  PanelController registerPanel(
    PanelId id, {
    required PanelSizing sizing,
    required PanelMode mode,
    required PanelAnchor anchor,
    PanelConstraints constraints = const PanelConstraints(),
    PanelVisuals visuals = const PanelVisuals(),
    bool isCollapsed = false,
    bool isVisible = true,
    bool isResizable = true,
  }) {
    if (_panels.containsKey(id)) {
      return _panels[id]!;
    }

    final controller = PanelController(
      id: id,
      sizing: sizing,
      mode: mode,
      anchor: anchor,
      constraints: constraints,
      visuals: visuals,
      isCollapsed: isCollapsed,
      isVisible: isVisible,
      isResizable: isResizable,
    );

    _panels[id] = controller;
    notifyListeners();
    return controller;
  }

  /// Retrieves a registered panel controller by its [id].
  ///
  /// Returns `null` if the panel is not registered.
  PanelController? getPanel(PanelId id) {
    return _panels[id];
  }

  /// Retrieves a registered panel controller by its [id].
  ///
  /// Throws an [Exception] if the panel is not found.
  PanelController getPanelOrThrow(PanelId id) {
    final panel = _panels[id];
    if (panel == null) {
      throw Exception('Panel with ID $id not found in LayoutController');
    }
    return panel;
  }

  /// Removes a panel from the registry.
  ///
  /// Disposes the associated [PanelController].
  void removePanel(PanelId id) {
    final panel = _panels.remove(id);
    if (panel != null) {
      panel.dispose();
      notifyListeners();
    }
  }

  /// Disposes all registered panel controllers and clears the registry.
  @override
  void dispose() {
    for (final panel in _panels.values) {
      panel.dispose();
    }
    _panels.clear();
    super.dispose();
  }
}
