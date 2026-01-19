import 'package:flutter/widgets.dart';
import 'package:equatable/equatable.dart';

import '../constants.dart';

/// Defines the visual styling for the resize handles in the layout system.
///
/// Resize handles appear between resizable inline panels.
/// You can customize their color, width, and add an optional grip icon.
@immutable
class ResizeHandleThemeData extends Equatable {
  /// Creates a [ResizeHandleThemeData].
  const ResizeHandleThemeData({
    this.color = kDefaultHandleColor,
    this.width = kDefaultHandleWidth,
    this.hitTestWidth = kDefaultHandleHitTestWidth,
    this.iconSize = kDefaultHandleIconSize,
    this.icon,
    this.iconColor,
    this.iconAlignment = Alignment.center,
  });

  /// The color of the resize handle line.
  final Color color;

  /// The visual width of the resize handle line.
  final double width;

  /// The width of the area that captures mouse events for resizing.
  /// Increasing this makes the handle easier to grab without making it visually thicker.
  final double hitTestWidth;

  /// The optional icon to display in the resize handle (e.g., a grip or dots).
  final IconData? icon;

  /// The color of the resize handle icon.
  final Color? iconColor;

  /// The size of the resize handle icon.
  final double iconSize;

  /// The alignment of the icon within the resize handle.
  final Alignment iconAlignment;

  @override
  List<Object?> get props => [
    color,
    width,
    hitTestWidth,
    icon,
    iconColor,
    iconSize,
    iconAlignment,
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
  bool updateShouldNotify(ResizeHandleTheme oldWidget) =>
      data != oldWidget.data;
}