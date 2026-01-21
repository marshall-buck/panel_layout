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
///     headerPadding: 12.0,
///     headerDecoration: BoxDecoration(color: Colors.grey[200]),
///   ),
///   child: PanelLayout(...),
/// )
/// ```
@immutable
class PanelThemeData extends Equatable {
  const PanelThemeData({
    this.headerPadding = kDefaultHeaderPadding,
    this.headerDecoration,
    this.titleStyle,
    this.iconColor,
    this.iconSize = kDefaultIconSize,
    this.panelBoxDecoration,
    this.railDecoration,
    this.railPadding = kDefaultRailPadding,
  });

  /// The vertical padding applied to the top and bottom of the panel header.
  ///
  /// The total height of the header is calculated as:
  /// `iconSize + (headerPadding * 2)`.
  ///
  /// This can be overridden by providing an explicit `headerHeight` to a panel.
  final double headerPadding;

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

  /// The total padding (horizontal + vertical depending on axis) around the icon in the rail.
  final double railPadding;

  @override
  List<Object?> get props => [
        headerPadding,
        headerDecoration,
        titleStyle,
        iconColor,
        iconSize,
        panelBoxDecoration,
        railDecoration,
        railPadding,
      ];

  PanelThemeData copyWith({
    double? headerPadding,
    BoxDecoration? headerDecoration,
    TextStyle? titleStyle,
    Color? iconColor,
    double? iconSize,
    BoxDecoration? panelBoxDecoration,
    BoxDecoration? railDecoration,
    double? railPadding,
  }) {
    return PanelThemeData(
      headerPadding: headerPadding ?? this.headerPadding,
      headerDecoration: headerDecoration ?? this.headerDecoration,
      titleStyle: titleStyle ?? this.titleStyle,
      iconColor: iconColor ?? this.iconColor,
      iconSize: iconSize ?? this.iconSize,
      panelBoxDecoration: panelBoxDecoration ?? this.panelBoxDecoration,
      railDecoration: railDecoration ?? this.railDecoration,
      railPadding: railPadding ?? this.railPadding,
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
