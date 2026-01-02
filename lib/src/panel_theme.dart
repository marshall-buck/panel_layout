import 'package:flutter/widgets.dart';

/// Defines the visual styling for the panel layout system.
///
/// This theme data is used by [LayoutPanel] and [PanelResizeHandle] to determine
/// colors, borders, and other visual properties.
///
/// See also:
///  * [PanelTheme], the InheritedWidget that provides this data to the tree.
@immutable
class PanelThemeData {
  /// Creates a [PanelThemeData].
  const PanelThemeData({
    this.backgroundColor = const Color(0xFFF3F3F3),
    this.borderColor = const Color(0xFFE5E5E5),
    this.resizeHandleColor = const Color(0x1A000000),
    this.resizeHandleHoverColor = const Color(0xFF0078D4),
    this.resizeHandleActiveColor = const Color(0xFF0078D4),
    this.resizeHandleWidth = 4.0,
    this.resizeHandleHitTestWidth = 12.0,
  });

  /// The default background color for panels.
  final Color backgroundColor;

  /// The color of panel borders.
  final Color borderColor;

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
        other.backgroundColor == backgroundColor &&
        other.borderColor == borderColor &&
        other.resizeHandleColor == resizeHandleColor &&
        other.resizeHandleHoverColor == resizeHandleHoverColor &&
        other.resizeHandleActiveColor == resizeHandleActiveColor &&
        other.resizeHandleWidth == resizeHandleWidth &&
        other.resizeHandleHitTestWidth == resizeHandleHitTestWidth;
  }

  @override
  int get hashCode => Object.hash(
        backgroundColor,
        borderColor,
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
  ///
  /// If no ancestor is found, returns a default [PanelThemeData].
  static PanelThemeData of(BuildContext context) {
    final PanelTheme? result = context.dependOnInheritedWidgetOfExactType<PanelTheme>();
    return result?.data ?? const PanelThemeData();
  }

  @override
  bool updateShouldNotify(PanelTheme oldWidget) => data != oldWidget.data;
}
