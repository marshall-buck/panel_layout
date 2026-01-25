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
    this.fixedPixelSizeOverride,
  });

  /// The current size of the panel.
  /// - For Fixed panels: Logical pixels (width or height).
  /// - For Flexible panels: Flex factor.
  double size;

  /// Whether the panel is currently visible.
  bool visible;

  /// Whether the panel is currently collapsed (minimized to rail).
  bool collapsed;

  /// If set, this panel behaves as a Fixed panel with this specific pixel size,
  /// ignoring its [flex] configuration. Used for animation stability.
  double? fixedPixelSizeOverride;

  /// Creates a copy of this state with the given fields replaced.
  PanelRuntimeState copyWith({
    double? size,
    bool? visible,
    bool? collapsed,
    double? fixedPixelSizeOverride,
  }) {
    // If explicit null is passed for override, we want to clear it? 
    // copyWith conventions usually ignore nulls.
    // We need a way to clear it.
    // Let's assume standard copyWith behavior: null means keep existing.
    // To clear, we might need a specific mechanism or just update the object directly since it's mutable?
    // Wait, the class members are not final, but `copyWith` creates a NEW instance.
    // To support clearing, I should probably make `fixedPixelSizeOverride` nullable in copyWith and handle it?
    // Or add `clearFixedSizeOverride` flag? 
    // Simpler: use a sentinel value? No.
    // I will use a separate method in StateManager to clear it, passing null to copyWith won't work if I follow standard pattern.
    // Actually, I can just make a dedicated `clearOverride` method in StateManager that constructs the state.
    // For now, standard copyWith.
    
    return PanelRuntimeState(
      size: size ?? this.size,
      visible: visible ?? this.visible,
      collapsed: collapsed ?? this.collapsed,
      fixedPixelSizeOverride: fixedPixelSizeOverride ?? this.fixedPixelSizeOverride,
    );
  }
}
