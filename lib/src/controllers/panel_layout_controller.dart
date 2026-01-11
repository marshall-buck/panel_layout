import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import '../models/panel_id.dart';

/// A controller for the [PanelLayout] widget.
///
/// Allows external components to manipulate the state of panels (e.g., toggle visibility, collapse/expand).
class PanelLayoutController extends ChangeNotifier {
  PanelLayoutStateInterface? _state;

  /// Attaches the controller to a [PanelLayout] state.
  @internal
  void attach(PanelLayoutStateInterface state) {
    _state = state;
  }

  /// Detaches the controller.
  @internal
  void detach() {
    _state = null;
  }

  /// Toggles the visibility of the panel with the given [id].
  void toggleVisible(PanelId id) {
    _state?.toggleVisible(id);
  }

  /// Toggles the collapsed state of the panel with the given [id].
  void toggleCollapsed(PanelId id) {
    _state?.toggleCollapsed(id);
  }

  /// Sets the visibility of the panel with the given [id].
  void setVisible(PanelId id, bool visible) {
    _state?.setVisible(id, visible);
  }

  /// Sets the collapsed state of the panel with the given [id].
  void setCollapsed(PanelId id, bool collapsed) {
    _state?.setCollapsed(id, collapsed);
  }
}

/// Interface that [PanelLayoutState] implements to receive commands.
@internal
abstract class PanelLayoutStateInterface {
  void toggleVisible(PanelId id);
  void toggleCollapsed(PanelId id);
  void setVisible(PanelId id, bool visible);
  void setCollapsed(PanelId id, bool collapsed);
}