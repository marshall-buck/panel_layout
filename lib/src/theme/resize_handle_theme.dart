import 'package:flutter/widgets.dart';
import 'package:equatable/equatable.dart';

import '../constants.dart';

/// Defines the visual styling for the resize handles in the layout system.
@immutable
class ResizeHandleThemeData extends Equatable {
  /// Creates a [ResizeHandleThemeData].
  const ResizeHandleThemeData({
    this.color = kDefaultHandleColor,
    this.hoverColor = kDefaultHandleHoverColor,
    this.activeColor = kDefaultHandleActiveColor,
    this.width = kDefaultHandleWidth,
    this.hitTestWidth = kDefaultHandleHitTestWidth,
    this.iconSize = kDefaultHandleIconSize,
    this.icon,
    this.iconColor,
    this.iconAlignment = Alignment.center,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.decoration,
    this.hoverDecoration,
    this.activeDecoration,
  });

  /// The color of the resize handle when idle.
  final Color color;

  /// The color of the resize handle when hovered.
  final Color hoverColor;

  /// The color of the resize handle when being dragged.
  final Color activeColor;

  /// The visual width of the resize handle.
  final double width;

  /// The width of the area that captures mouse events for resizing.
  final double hitTestWidth;

  /// The optional icon to display in the resize handle (e.g., a grip).
  final IconData? icon;

  /// The color of the resize handle icon.
  final Color? iconColor;

  /// The size of the resize handle icon.
  final double iconSize;

  /// The alignment of the icon within the resize handle.
  final Alignment iconAlignment;

  /// The border color of the resize handle.
  final Color? borderColor;

  /// The border width of the resize handle.
  final double? borderWidth;

  /// The border radius of the resize handle.
  final double? borderRadius;

  /// The decoration of the resize handle when idle.
  /// Overrides [color].
  final Decoration? decoration;

  /// The decoration of the resize handle when hovered.
  /// Overrides [hoverColor].
  final Decoration? hoverDecoration;

  /// The decoration of the resize handle when being dragged.
  /// Overrides [activeColor].
  final Decoration? activeDecoration;

  @override
  List<Object?> get props => [
    color,
    hoverColor,
    activeColor,
    width,
    hitTestWidth,
    icon,
    iconColor,
    iconSize,
    iconAlignment,
    borderColor,
    borderWidth,
    borderRadius,
    decoration,
    hoverDecoration,
    activeDecoration,
  ];
}

/// An inherited widget that provides [ResizeHandleThemeData] to its descendants.
class ResizeHandleTheme extends InheritedWidget {
  /// Creates a [ResizeHandleTheme].
  const ResizeHandleTheme({
    required this.data,
    required super.child,
    super.key,
  });

  /// The styling data provided by this theme.
  final ResizeHandleThemeData data;

  /// Retrieves the [ResizeHandleThemeData] from the closest [ResizeHandleTheme] ancestor.
  static ResizeHandleThemeData of(BuildContext context) {
    final ResizeHandleTheme? result = context
        .dependOnInheritedWidgetOfExactType<ResizeHandleTheme>();
    return result?.data ?? const ResizeHandleThemeData();
  }

  @override
  bool updateShouldNotify(ResizeHandleTheme oldWidget) => data != oldWidget.data;
}
