import 'package:flutter/widgets.dart';
import 'package:equatable/equatable.dart';

/// Configuration for the visual behavior of a layout panel.
///
/// This configuration controls the animation of the panel.
/// Visual styling (backgrounds, borders) should be handled by the widget
/// returned by the panel builder.
class PanelVisuals extends Equatable {
  const PanelVisuals({
    this.animationDuration = const Duration(milliseconds: 300),
    this.animationCurve = Curves.easeOutExpo,
  });

  final Duration animationDuration;
  final Curve animationCurve;

  PanelVisuals copyWith({Duration? animationDuration, Curve? animationCurve}) {
    return PanelVisuals(
      animationDuration: animationDuration ?? this.animationDuration,
      animationCurve: animationCurve ?? this.animationCurve,
    );
  }

  @override
  List<Object?> get props => [animationDuration, animationCurve];
}
