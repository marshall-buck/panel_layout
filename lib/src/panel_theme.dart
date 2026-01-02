import 'package:flutter/widgets.dart';

/// Defines the visual styling for the panel layout system.
///
/// This theme data is used by [PanelResizeHandle] to determine colors and dimensions.
@immutable
class PanelThemeData {
  /// Creates a [PanelThemeData].
  const PanelThemeData({
    this.resizeHandleColor = const Color(0x1A000000),
    this.resizeHandleHoverColor = const Color(0xFF0078D4),
    this.resizeHandleActiveColor = const Color(0xFF0078D4),
    this.resizeHandleWidth = 4.0,
    this.resizeHandleHitTestWidth = 12.0,
  });

  /// The color of the resize handle when idle.
  final Color resizeHandleColor;

  /// The color of the resize handle when hovered.
  final Color resizeHandleHoverColor;

  /// The color of the resize handle when being dragged.
  final Color resizeHandleActiveColor;

  /// The visual width of the resize handle.
  final double resizeHandleWidth;

  /// The width of the area that captures mouse events for resizing.
  final double resizeHandleHitTestWidth;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PanelThemeData &&
        other.resizeHandleColor == resizeHandleColor &&
        other.resizeHandleHoverColor == resizeHandleHoverColor &&
        other.resizeHandleActiveColor == resizeHandleActiveColor &&
        other.resizeHandleWidth == resizeHandleWidth &&
        other.resizeHandleHitTestWidth == resizeHandleHitTestWidth;
  }

  @override
  int get hashCode => Object.hash(
        resizeHandleColor,
        resizeHandleHoverColor,
        resizeHandleActiveColor,
        resizeHandleWidth,
        resizeHandleHitTestWidth,
      );
}

/// An inherited widget that provides [PanelThemeData] to its descendants.
class PanelTheme extends InheritedWidget {
  /// Creates a [PanelTheme].
  const PanelTheme({
    required this.data,
    required super.child,
    super.key,
  });

  /// The styling data provided by this theme.
  final PanelThemeData data;

  /// Retrieves the [PanelThemeData] from the closest [PanelTheme] ancestor.
  static PanelThemeData of(BuildContext context) {
    final PanelTheme? result = context.dependOnInheritedWidgetOfExactType<PanelTheme>();
    return result?.data ?? const PanelThemeData();
  }

  @override
  bool updateShouldNotify(PanelTheme oldWidget) => data != oldWidget.data;
}