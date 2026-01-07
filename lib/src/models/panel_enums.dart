/// Defines how a panel interacts with the main layout flow.
enum PanelMode {
  /// The panel is part of the linear layout (Row/Column).
  /// It pushes other panels aside.
  inline,

  /// The panel floats on top of the layout.
  /// It does not affect the size/position of inline panels.
  /// Useful for temporary drawers, dialogs, or floating tools.
  overlay,

  /// The panel is tracked by the controller but not rendered by the [PanelArea].
  /// Useful for headless state management or custom rendering integration.
  detached,
}

/// Defines which edge a panel is logically attached to.
///
/// This determines:
/// 1. The direction of resizing (e.g., [left] panels resize horizontally).
/// 2. The alignment of overlay panels (e.g., [right] overlays align to the right).
/// 3. The scroll direction if the content overflows.
enum PanelAnchor { left, right, top, bottom }
