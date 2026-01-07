import 'package:flutter/widgets.dart';
import 'package:equatable/equatable.dart';

/// Defines the visual styling for the panel layout system.
///
/// This theme data is used by [PanelResizeHandle] to determine colors and dimensions.
@immutable
class PanelThemeData extends Equatable {
  /// Creates a [PanelThemeData].
  const PanelThemeData({
    this.resizeHandleColor = const Color(0x1A000000),
    this.resizeHandleHoverColor = const Color(0xFF0078D4),
    this.resizeHandleActiveColor = const Color(0xFF0078D4),
    this.resizeHandleWidth = 4.0,
    this.resizeHandleHitTestWidth = 12.0,
    this.resizeHandleDecoration,
    this.resizeHandleHoverDecoration,
    this.resizeHandleActiveDecoration,
    this.panelDecoration,
    this.panelPadding,
  });

  /// The color of the resize handle when idle.
  ///
  /// Ignored if [resizeHandleDecoration] is provided.
  final Color resizeHandleColor;

  /// The color of the resize handle when hovered.
  ///
  /// Ignored if [resizeHandleHoverDecoration] is provided.
  final Color resizeHandleHoverColor;

  /// The color of the resize handle when being dragged.
  ///
  /// Ignored if [resizeHandleActiveDecoration] is provided.
  final Color resizeHandleActiveColor;

  /// The visual width of the resize handle.
  final double resizeHandleWidth;

  /// The width of the area that captures mouse events for resizing.
  final double resizeHandleHitTestWidth;

  /// The decoration of the resize handle when idle.
  ///
  /// Overrides [resizeHandleColor].
  final Decoration? resizeHandleDecoration;

  /// The decoration of the resize handle when hovered.
  ///
  /// Overrides [resizeHandleHoverColor].
  final Decoration? resizeHandleHoverDecoration;

  /// The decoration of the resize handle when being dragged.
  ///
  /// Overrides [resizeHandleActiveColor].
  final Decoration? resizeHandleActiveDecoration;

  /// The decoration to apply to the panel container.
  final Decoration? panelDecoration;

  /// The padding to apply to the panel content.
  final EdgeInsetsGeometry? panelPadding;

  @override
  List<Object?> get props => [
    resizeHandleColor,
    resizeHandleHoverColor,
    resizeHandleActiveColor,
    resizeHandleWidth,
    resizeHandleHitTestWidth,
    resizeHandleDecoration,
    resizeHandleHoverDecoration,
    resizeHandleActiveDecoration,
    panelDecoration,
    panelPadding,
  ];
}

/// An inherited widget that provides [PanelThemeData] to its descendants.
class PanelTheme extends InheritedWidget {
  /// Creates a [PanelTheme].
  const PanelTheme({required this.data, required super.child, super.key});

  /// The styling data provided by this theme.
  final PanelThemeData data;

  /// Retrieves the [PanelThemeData] from the closest [PanelTheme] ancestor.
  static PanelThemeData of(BuildContext context) {
    final PanelTheme? result = context
        .dependOnInheritedWidgetOfExactType<PanelTheme>();
    return result?.data ?? const PanelThemeData();
  }

  @override
  bool updateShouldNotify(PanelTheme oldWidget) => data != oldWidget.data;
}
