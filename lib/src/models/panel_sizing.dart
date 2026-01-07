import 'package:equatable/equatable.dart';

sealed class PanelSizing extends Equatable {
  const PanelSizing();
  
  @override
  List<Object?> get props => [];
}

/// The panel has a specific size in logical pixels.
///
/// Use this for sidebars, toolbars, or any panel that should maintain
/// a constant width/height regardless of available space.
class FixedSizing extends PanelSizing {
  /// [size]: The size in logical pixels.
  const FixedSizing(this.size);
  
  final double size;
  
  @override
  List<Object?> get props => [size];
}

/// The panel shares available space with other flexible panels.
///
/// Use this for main content areas. This behaves like a Flutter [Expanded] widget.
class FlexibleSizing extends PanelSizing {
  /// [weight]: The flex factor. A panel with weight 2 takes twice the space
  /// of a panel with weight 1.
  const FlexibleSizing(this.weight);
  
  final double weight;
  
  @override
  List<Object?> get props => [weight];
}

/// The panel sizes itself to fit its child content.
///
/// Use this when the content determines the size (e.g., a settings panel
/// that should only be as wide as its widest toggle).
class ContentSizing extends PanelSizing {
  const ContentSizing();
}
