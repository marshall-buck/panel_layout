/// Defines which edge a panel is logically attached to.
///
/// This determines:
/// 1. The direction of resizing (e.g., [left] panels resize horizontally).
/// 2. The alignment of overlay panels (e.g., [right] overlays align to the right).
/// 3. The scroll direction if the content overflows.
enum PanelAnchor { left, right, top, bottom }

/// Defines the direction a panel animates when opening (expanding).
///
/// This is used to determine the rotation of the toggle icon.
/// For example, if a panel [opensRight], a left-pointing chevron (default icon)
/// will be rotated to point right when the panel is collapsed (indicating it will open right),
/// and left when open (indicating it will close left).
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
