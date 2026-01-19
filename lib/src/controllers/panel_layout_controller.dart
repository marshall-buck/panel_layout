import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import '../models/panel_id.dart';

/// A controller for the [PanelLayout] widget.
///
/// Use this controller to manipulate the state of panels programmatically
/// from outside the [PanelLayout] widget tree.
///
/// Typical usage:
/// 1. Create a [PanelLayoutController].
/// 2. Pass it to the [PanelLayout] constructor.
/// 3. Call methods like [toggleVisible] or [setCollapsed] in response to user events.
///
/// Don't forget to [dispose] the controller when it is no longer needed.
class PanelLayoutController extends ChangeNotifier {
  PanelLayoutStateInterface? _state;

  /// Attaches the controller to a [PanelLayout] state.
  ///
  /// This is called automatically by the [PanelLayout] widget.
  @internal
  void attach(PanelLayoutStateInterface state) {
    _state = state;
  }

  /// Detaches the controller from the [PanelLayout] state.
  ///
  /// This is called automatically when the [PanelLayout] is disposed or updated.
  @internal
  void detach() {
    _state = null;
  }

  /// Toggles the visibility of the panel with the given [id].
  ///
  /// If the panel is visible, it will be hidden. If hidden, it will be shown.
  void toggleVisible(PanelId id) {
    _state?.toggleVisible(id);
  }

  /// Toggles the collapsed state of the panel with the given [id].
  ///
  /// If the panel is expanded, it will collapse to its rail size.
  /// If collapsed, it will expand to its last known size.
  void toggleCollapsed(PanelId id) {
    _state?.toggleCollapsed(id);
  }

  /// Sets the visibility of the panel with the given [id].
  ///
  /// [visible] determines whether the panel should be shown (true) or hidden (false).
  void setVisible(PanelId id, bool visible) {
    _state?.setVisible(id, visible);
  }

  /// Sets the collapsed state of the panel with the given [id].
  ///
  /// [collapsed] determines whether the panel should be collapsed (true) or expanded (false).
  void setCollapsed(PanelId id, bool collapsed) {
    _state?.setCollapsed(id, collapsed);
  }
}

/// Interface that [PanelLayoutState] implements to receive commands.
///
/// This decouples the controller from the widget state implementation.
@internal
abstract class PanelLayoutStateInterface {
  void toggleVisible(PanelId id);
  void toggleCollapsed(PanelId id);
  void setVisible(PanelId id, bool visible);
  void setCollapsed(PanelId id, bool collapsed);
}