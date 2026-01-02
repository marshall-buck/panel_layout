import 'package:flutter/widgets.dart';

/// A strongly-typed identifier for a panel in the layout system.
///
/// This wrapper prevents "string typed" errors and allows for future
/// extensibility if additional metadata needs to be associated with an ID.
@immutable
class PanelId {
  /// Creates a [PanelId] with the given [value].
  const PanelId(this.value);

  /// The underlying string value of the identifier.
  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PanelId && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'PanelId($value)';
}

/// Defines the strategy used to calculate a panel's size along the main axis.
sealed class PanelSizing {
  /// Base constructor for [PanelSizing].
  const PanelSizing();
}

/// A sizing strategy where the panel has a fixed size in logical pixels.
class FixedSizing extends PanelSizing {
  /// Creates a [FixedSizing] strategy.
  ///
  /// [size] must be non-negative.
  const FixedSizing(this.size);

  /// The size of the panel in logical pixels.
  final double size;
}

/// A sizing strategy where the panel takes up a portion of the remaining space.
class FlexibleSizing extends PanelSizing {
  /// Creates a [FlexibleSizing] strategy.
  ///
  /// [weight] is the flex factor. Defaults to 1.0.
  const FlexibleSizing(this.weight);

  /// The flex weight of the panel.
  final double weight;
}

/// A sizing strategy where the panel wraps its content.
class ContentSizing extends PanelSizing {
  /// Creates a [ContentSizing] strategy.
  const ContentSizing();
}

/// Defines how a panel is positioned within the layout.
enum PanelMode {
  /// The panel is part of the flow layout (Row or Column).
  inline,

  /// The panel floats on top of the content (Stack).
  overlay,

  /// The panel is detached from the main window.
  detached,
}

/// Defines which edge of the parent container a panel is anchored to.
enum PanelAnchor {
  /// Anchored to the left edge of the container.
  left,

  /// Anchored to the right edge of the container.
  right,

  /// Anchored to the top edge of the container.
  top,

  /// Anchored to the bottom edge of the container.
  bottom,
}

/// Constraints that limit the resizing behavior of a panel.
@immutable
class PanelConstraints {
  /// Creates a [PanelConstraints] object.
  const PanelConstraints({
    this.minSize = 0.0,
    this.maxSize = double.infinity,
    this.collapsedSize = 48.0,
  });

  /// The minimum size (width or height) the panel can be resized to in pixels.
  final double minSize;

  /// The maximum size (width or height) the panel can be resized to in pixels.
  final double maxSize;

  /// The size of the panel when it is in the collapsed state.
  final double collapsedSize;
}

/// Configuration for the visual appearance of a layout panel.
@immutable
class PanelVisuals {
  /// Creates a [PanelVisuals] configuration.
  const PanelVisuals({
    this.useAcrylic = false,
    this.tintAlpha,
    this.luminosityAlpha,
    this.blurAmount,
    this.showBorders = true,
    this.borderRadius,
    this.padding,
    this.elevation = 0.0,
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeOutExpo,
  });

  /// Whether to apply the Acrylic blur effect to the panel's background.
  final bool useAcrylic;

  /// The opacity of the tint layer for the Acrylic effect (0.0 - 1.0).
  final double? tintAlpha;

  /// The opacity of the luminosity layer for the Acrylic effect (0.0 - 1.0).
  final double? luminosityAlpha;

  /// The gaussian blur radius for the Acrylic effect.
  final double? blurAmount;

  /// Whether to render borders around the panel.
  final bool showBorders;

  /// The border radius to apply to the panel.
  final BorderRadius? borderRadius;

  /// The padding applied around the panel's content [child].
  final EdgeInsets? padding;

  /// The shadow elevation of the panel.
  final double elevation;

  /// The duration of size and state change animations.
  final Duration animationDuration;

  /// The curve used for size and state change animations.
  final Curve animationCurve;
}