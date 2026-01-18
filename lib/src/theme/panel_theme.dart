import 'package:flutter/widgets.dart';
import 'package:equatable/equatable.dart';

/// Defines the visual styling for panels and their headers.
@immutable
class PanelThemeData extends Equatable {
  const PanelThemeData({
    this.headerHeight = 32.0,
    this.headerDecoration,
    this.headerTextStyle,
    this.headerIconColor,
    this.headerIconSize = 16.0,
    this.panelDecoration,
  });

  /// The height of the panel header.
  final double headerHeight;

  /// The decoration (background, border) for the panel header.
  final BoxDecoration? headerDecoration;

  /// The text style for the panel title.
  final TextStyle? headerTextStyle;

  /// The color of the header icon.
  final Color? headerIconColor;

  /// The size of the header icon.
  final double headerIconSize;

  /// The decoration (background, border) for the panel content container.
  final BoxDecoration? panelDecoration;

  @override
  List<Object?> get props => [
    headerHeight,
    headerDecoration,
    headerTextStyle,
    headerIconColor,
    headerIconSize,
    panelDecoration,
  ];

  PanelThemeData copyWith({
    double? headerHeight,
    BoxDecoration? headerDecoration,
    TextStyle? headerTextStyle,
    Color? headerIconColor,
    double? headerIconSize,
    BoxDecoration? panelDecoration,
  }) {
    return PanelThemeData(
      headerHeight: headerHeight ?? this.headerHeight,
      headerDecoration: headerDecoration ?? this.headerDecoration,
      headerTextStyle: headerTextStyle ?? this.headerTextStyle,
      headerIconColor: headerIconColor ?? this.headerIconColor,
      headerIconSize: headerIconSize ?? this.headerIconSize,
      panelDecoration: panelDecoration ?? this.panelDecoration,
    );
  }
}

/// An inherited widget that provides [PanelThemeData] to its descendants.
class PanelTheme extends InheritedWidget {
  const PanelTheme({required this.data, required super.child, super.key});

  final PanelThemeData data;

  static PanelThemeData of(BuildContext context) {
    final PanelTheme? result = context
        .dependOnInheritedWidgetOfExactType<PanelTheme>();
    return result?.data ?? const PanelThemeData();
  }

  @override
  bool updateShouldNotify(PanelTheme oldWidget) => data != oldWidget.data;
}
