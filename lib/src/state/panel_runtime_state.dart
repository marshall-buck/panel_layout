/// Represents the ephemeral runtime state of a panel.
///
/// This state is managed by the [PanelLayout] engine and persists
/// across widget rebuilds (e.g., preserving a user-dragged width).
///
/// **Note**: This state is currently ephemeral and will be lost on hot restart
/// or if the [PanelLayout] widget is completely removed from the tree.
/// (Persistence is planned for a future release).
class PanelRuntimeState {
  PanelRuntimeState({
    required this.size,
    required this.visible,
    required this.collapsed,
  });

  /// The current size of the panel.
  /// - For Fixed panels: Logical pixels (width or height).
  /// - For Flexible panels: Flex factor.
  double size;

  /// Whether the panel is currently visible.
  bool visible;

  /// Whether the panel is currently collapsed (minimized to rail).
  bool collapsed;

  /// Creates a copy of this state with the given fields replaced.
  PanelRuntimeState copyWith({double? size, bool? visible, bool? collapsed}) {
    return PanelRuntimeState(
      size: size ?? this.size,
      visible: visible ?? this.visible,
      collapsed: collapsed ?? this.collapsed,
    );
  }
}
