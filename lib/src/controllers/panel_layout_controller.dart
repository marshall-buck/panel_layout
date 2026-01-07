import 'package:flutter/widgets.dart';

import 'panel_controller.dart';
import '../models/panel_id.dart';
import '../models/panel_sizing.dart';
import '../models/panel_enums.dart';
import '../models/panel_constraints.dart';
import '../models/panel_visuals.dart';

/// The central registry and orchestrator for all [PanelController]s in the application.
///
/// The [PanelLayoutController] maintains a map of all registered panels, allowing different
/// parts of the application to look up and modify panel state.
///
/// It extends [ChangeNotifier] to notify listeners when panels are registered or removed.
class PanelLayoutController extends ChangeNotifier {
  final Map<PanelId, PanelController> _panels = {};

  /// Registers a panel with the controller.
  ///
  /// If a panel with the same [id] already exists, it is returned directly.
  /// Otherwise, a new [PanelController] is created and stored.
  ///
  /// [id] A unique identifier for the panel. Used to retrieve it later.
  ///
  /// [sizing] Determines how the panel's size is calculated.
  ///   - [FixedSizing(pixels)]: The panel has a fixed width/height in logical pixels.
  ///   - [FlexibleSizing(weight)]: The panel takes up a proportion of remaining space (like Flex).
  ///   - [ContentSizing()]: The panel shrinks to fit its child content.
  ///
  /// [mode] Defines how the panel is positioned in the layout.
  ///   - [PanelMode.inline]: The panel sits within the flow of the [PanelArea] (e.g., in the row/column).
  ///   - [PanelMode.overlay]: The panel floats on top of other content, anchored to a side.
  ///   - [PanelMode.detached]: The panel is registered but not shown in the main area (rare).
  ///
  /// [anchor] Specifies which edge of the container the panel is attached to.
  ///   - [PanelAnchor.left]/[PanelAnchor.right]: Vertical panels (width is sized).
  ///   - [PanelAnchor.top]/[PanelAnchor.bottom]: Horizontal panels (height is sized).
  ///
  /// [anchorPanel] Optional ID of another panel to anchor this panel to.
  ///   - If provided, the [anchor] property determines the position relative to this target panel.
  ///
  /// [constraints] detailed limits on the panel's dimensions.
  ///   - [minSize]: The minimum size (pixels) the user can resize it to.
  ///   - [maxSize]: The maximum size (pixels) the user can resize it to.
  ///   - [collapsedSize]: The size (pixels) when the panel is collapsed (if not 0).
  ///
  /// [visuals] Configuration for animations and transitions.
  ///   - [animationDuration]: How long resize/toggle animations take.
  ///   - [animationCurve]: The easing curve for animations.
  ///
  /// [isCollapsed]  Whether the panel starts in a collapsed state.
  ///
  /// [isVisible] Whether the panel is initially visible.
  ///   - If `false`, the panel is hidden.
  ///   - **Note**: Fixed/Content sized panels will animate to size 0 when hidden.
  ///   - **Note**: Flexible panels are removed from the layout immediately when hidden.
  ///
  /// [isResizable]  Whether the user can drag the edge of this panel to resize it.
  PanelController registerPanel(
    PanelId id, {
    required Widget Function(BuildContext, PanelController) builder,
    required PanelSizing sizing,
    required PanelMode mode,
    required PanelAnchor anchor,
    PanelId? anchorPanel,
    AlignmentGeometry? alignment,
    LayerLink? anchorLink,
    CrossAxisAlignment? crossAxisAlignment,
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
      builder: builder,
      sizing: sizing,
      mode: mode,
      anchor: anchor,
      anchorPanel: anchorPanel,
      alignment: alignment,
      anchorLink: anchorLink,
      crossAxisAlignment: crossAxisAlignment,
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
