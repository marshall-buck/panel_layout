import 'panel_controller.dart';
import 'panel_data.dart';

/// The central registry and orchestrator for all [PanelController]s in the application.
///
/// The [LayoutController] maintains a map of all registered panels, allowing different
/// parts of the application to look up and modify panel state.
class LayoutController {
  final Map<PanelId, PanelController> _panels = {};

  /// Registers a panel with the controller.
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
    return controller;
  }

  /// Retrieves a registered panel controller by its [id].
  PanelController? getPanel(PanelId id) {
    return _panels[id];
  }

  /// Retrieves a registered panel controller by its [id].
  PanelController getPanelOrThrow(PanelId id) {
    final panel = _panels[id];
    if (panel == null) {
      throw Exception('Panel with ID $id not found in LayoutController');
    }
    return panel;
  }

  /// Removes a panel from the registry.
  void removePanel(PanelId id) {
    final panel = _panels.remove(id);
    panel?.dispose();
  }

  /// Disposes all registered panel controllers and clears the registry.
  void dispose() {
    for (final panel in _panels.values) {
      panel.dispose();
    }
    _panels.clear();
  }
}