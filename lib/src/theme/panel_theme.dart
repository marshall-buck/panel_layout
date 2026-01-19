import 'package:flutter/widgets.dart';
import 'package:equatable/equatable.dart';
import '../constants.dart';

/// Defines the visual styling for panels and their headers.
///
/// You can provide a [PanelTheme] widget above your [PanelLayout] to
/// automatically apply these styles to all panels in the subtree.
///
/// Example:
/// ```dart
/// PanelTheme(
///   data: PanelThemeData(
///     headerHeight: 40.0,
///     headerDecoration: BoxDecoration(color: Colors.grey[200]),
///   ),
///   child: PanelLayout(...),
/// )
/// ```
@immutable
class PanelThemeData extends Equatable {
  const PanelThemeData({
    this.headerHeight = kDefaultHeaderHeight,
    this.headerDecoration,
    this.titleStyle,
    this.iconColor,
    this.iconSize = kDefaultIconSize,
    this.panelBoxDecoration,
    this.railDecoration,
  });

  /// The height of the panel header.
  final double headerHeight;

  /// The decoration (background, border) for the panel header.
  final BoxDecoration? headerDecoration;

  /// The text style for the panel title.
  final TextStyle? titleStyle;

  /// The color of the icon.
  final Color? iconColor;

  /// The size of the icon.
  final double iconSize;

  /// The decoration (background, border) for the panel content container.
  final BoxDecoration? panelBoxDecoration;

  /// The decoration (background, border) for the collapsed rail.
  final BoxDecoration? railDecoration;

  @override
  List<Object?> get props => [
        headerHeight,
        headerDecoration,
        titleStyle,
        iconColor,
        iconSize,
        panelBoxDecoration,
        railDecoration,
      ];

  PanelThemeData copyWith({
    double? headerHeight,
    BoxDecoration? headerDecoration,
    TextStyle? titleStyle,
    Color? iconColor,
    double? iconSize,
    BoxDecoration? panelBoxDecoration,
    BoxDecoration? railDecoration,
  }) {
    return PanelThemeData(
      headerHeight: headerHeight ?? this.headerHeight,
      headerDecoration: headerDecoration ?? this.headerDecoration,
      titleStyle: titleStyle ?? this.titleStyle,
      iconColor: iconColor ?? this.iconColor,
      iconSize: iconSize ?? this.iconSize,
      panelBoxDecoration: panelBoxDecoration ?? this.panelBoxDecoration,
      railDecoration: railDecoration ?? this.railDecoration,
    );
  }
}

/// An inherited widget that provides [PanelThemeData] to its descendants.
class PanelTheme extends InheritedWidget {
  const PanelTheme({required this.data, required super.child, super.key});

  final PanelThemeData data;

  static PanelThemeData of(BuildContext context) {
    final PanelTheme? result =
        context.dependOnInheritedWidgetOfExactType<PanelTheme>();
    return result?.data ?? const PanelThemeData();
  }

  @override
  bool updateShouldNotify(PanelTheme oldWidget) => data != oldWidget.data;
}