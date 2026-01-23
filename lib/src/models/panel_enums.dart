/// Defines which edge a panel is logically attached to.
///
/// The anchor determines several key behaviors:
/// 1. **Resize Direction**: [left] panels resize horizontally from the right edge.
///    [top] panels resize vertically from the bottom edge.
/// 2. **Overlay Alignment**: [right] overlays are aligned to the right of the screen
///    or their anchor target.
/// 3. **Collapse Direction**: By default, a [left] panel collapses to the left.
enum PanelAnchor {
  /// Anchored to the left side. Resizes horizontally.
  left,

  /// Anchored to the right side. Resizes horizontally.
  right,

  /// Anchored to the top. Resizes vertically.
  top,

  /// Anchored to the bottom. Resizes vertically.
  bottom,
}

/// Defines the direction a panel animates when opening (expanding).
///
/// This is primarily used to determine the rotation of the toggle icon.
/// For example, if a panel [opensRight], a standard left-pointing chevron (`<`)
/// will be rotated 180 degrees (`>`) when the panel is collapsed, indicating
/// that clicking it will open the panel to the right.
enum PanelAnimationDirection {
  /// The panel expands towards the left.
  opensLeft,

  /// The panel expands towards the right.
  opensRight,

  /// The panel expands upwards.
  opensUp,

  /// The panel expands downwards.
  opensDown,
}

/// Defines the action to take when the panel's header icon is pressed.
enum PanelAction {
  /// No action is taken.
  none,

  /// Toggles the collapsed/expanded state of the panel (InlinePanels).
  collapse,

  /// Closes (hides) the panel entirely (OverlayPanels).
  close,
}
