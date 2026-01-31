import 'package:meta/meta.dart';
import '../models/panel_id.dart';

/// A controller for the [PanelArea] widget.
///
/// Use this controller to manipulate the state of panels programmatically
/// from outside the [PanelArea] widget tree.
///
/// Typical usage:
/// 1. Create a [PanelAreaController].
/// 2. Pass it to the [PanelArea] constructor.
/// 3. Call methods like [toggleVisible] or [setCollapsed] in response to user events.
///
/// Don't forget to [dispose] the controller when it is no longer needed.
class PanelAreaController {
  PanelLayoutStateInterface? _state;

  /// Attaches the controller to a [PanelArea] state.
  ///
  /// This is called automatically by the [PanelArea] widget.
  @internal
  void attach(PanelLayoutStateInterface state) {
    _state = state;
  }

  /// Detaches the controller from the [PanelArea] state.
  ///
  /// This is called automatically when the [PanelArea] is disposed or updated.
  @internal
  void detach() {
    _state = null;
  }

  /// Disposes the controller.
  void dispose() {
    detach();
  }

  /// Toggles the visibility of the panel with the given [id].
  ///
  /// **Visibility** refers to whether the panel is shown at all.
  /// - **Visible**: The panel is displayed (either expanded or collapsed).
  /// - **Hidden**: The panel is completely removed from the layout and takes up no space.
  ///
  /// To minimize a panel without hiding it completely, use [toggleCollapsed] instead.
  void toggleVisible(PanelId id) {
    _state?.toggleVisible(id);
  }

  /// Toggles the collapsed state of the panel with the given [id].
  ///
  /// **Collapsing** refers to minimizing the panel to its "rail" size (e.g., just the icon).
  /// - **Collapsed**: The panel is visible but minimized to its header/rail size.
  /// - **Expanded**: The panel is visible and showing its full content.
  ///
  /// This does not affect whether the panel is [visible] or hidden.
  void toggleCollapsed(PanelId id) {
    _state?.toggleCollapsed(id);
  }

  /// Sets the visibility of the panel with the given [id].
  ///
  /// **Visibility** refers to whether the panel is shown at all.
  /// - If [visible] is `true`, the panel is displayed (either expanded or collapsed).
  /// - If [visible] is `false`, the panel is completely hidden and takes up no space.
  ///
  /// To minimize a panel without hiding it completely, use [setCollapsed] instead.
  void setVisible(PanelId id, bool visible) {
    _state?.setVisible(id, visible);
  }

  /// Sets the collapsed state of the panel with the given [id].
  ///
  /// **Collapsing** refers to minimizing the panel to its "rail" size (e.g., just the icon).
  /// - If [collapsed] is `true`, the panel is minimized to its header/rail size.
  /// - If [collapsed] is `false`, the panel is expanded to its full content size.
  ///
  /// A collapsed panel remains visible on screen. To hide it completely, use [setVisible].
  void setCollapsed(PanelId id, bool collapsed) {
    _state?.setCollapsed(id, collapsed);
  }

  /// Programmatically updates the size of the panel with the given [id].
  ///
  /// For flexible panels, [size] represents the new layout weight (e.g., 2.0).
  /// For fixed panels, [size] represents the new logical pixel size (e.g., 300.0).
  void updateSize(PanelId id, double size) {
    _state?.updateSize(id, size);
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
  void updateSize(PanelId id, double size);
}
