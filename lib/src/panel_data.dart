import 'package:flutter/widgets.dart';

/// A strongly-typed identifier for a panel in the layout system.
@immutable
class PanelId {
  const PanelId(this.value);
  final String value;
  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PanelId && runtimeType == other.runtimeType && value == other.value;
  @override
  int get hashCode => value.hashCode;
  @override
  String toString() => 'PanelId($value)';
}

sealed class PanelSizing {
  const PanelSizing();
}

/// The panel has a specific size in logical pixels.
///
/// Use this for sidebars, toolbars, or any panel that should maintain
/// a constant width/height regardless of available space.
class FixedSizing extends PanelSizing {
  /// [size]: The size in logical pixels.
  const FixedSizing(this.size);
  final double size;
}

/// The panel shares available space with other flexible panels.
///
/// Use this for main content areas. This behaves like a Flutter [Expanded] widget.
class FlexibleSizing extends PanelSizing {
  /// [weight]: The flex factor. A panel with weight 2 takes twice the space
  /// of a panel with weight 1.
  const FlexibleSizing(this.weight);
  final double weight;
}

/// The panel sizes itself to fit its child content.
///
/// Use this when the content determines the size (e.g., a settings panel
/// that should only be as wide as its widest toggle).
///
/// **Note**: If [PanelController.isResizable] is true, resizing a ContentSizing
/// panel will convert it to [FixedSizing] at the new size.
class ContentSizing extends PanelSizing {
  const ContentSizing();
}

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
enum PanelAnchor {
  left,
  right,
  top,
  bottom,
}

@immutable
class PanelConstraints {
  const PanelConstraints({
    this.minSize = 0.0,
    this.maxSize = double.infinity,
    this.collapsedSize = 48.0,
  });
  final double minSize;
  final double maxSize;
  final double collapsedSize;
}

/// Configuration for the visual behavior of a layout panel.
///
/// This configuration controls the animation of the panel.
/// Visual styling (backgrounds, borders) should be handled by the widget
/// returned by the panel builder.
@immutable
class PanelVisuals {
  const PanelVisuals({
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeOutExpo,
  });

  final Duration animationDuration;
  final Curve animationCurve;

  PanelVisuals copyWith({
    Duration? animationDuration,
    Curve? animationCurve,
  }) {
    return PanelVisuals(
      animationDuration: animationDuration ?? this.animationDuration,
      animationCurve: animationCurve ?? this.animationCurve,
    );
  }
}
