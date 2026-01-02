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

class FixedSizing extends PanelSizing {
  const FixedSizing(this.size);
  final double size;
}

class FlexibleSizing extends PanelSizing {
  const FlexibleSizing(this.weight);
  final double weight;
}

class ContentSizing extends PanelSizing {
  const ContentSizing();
}

enum PanelMode {
  inline,
  overlay,
  detached,
}

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
