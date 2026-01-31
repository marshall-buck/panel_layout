import 'package:flutter/widgets.dart';
import 'package:equatable/equatable.dart';
import '../core/constants.dart';

/// Configuration for the [PanelArea] system.
///
/// This class defines the visual styling and behavior defaults for all panels
/// and resize handles within the layout.
///
/// Provide this to the [PanelArea.style] parameter.
@immutable
class PanelStyle extends Equatable {
  const PanelStyle({
    // Panel Header & Content
    this.headerPadding = kDefaultHeaderPadding,
    this.headerDecoration,
    this.titleTextStyle,
    this.iconColor,
    this.iconSize = kDefaultIconSize,
    this.panelBoxDecoration,

    // Rail (Collapsed State)
    this.railDecoration,
    this.railPadding = kDefaultRailPadding,

    // Resize Handles
    this.handleColor = kDefaultHandleColor,
    this.handleWidth = kDefaultHandleWidth,
    this.handleHitTestWidth = kDefaultHandleHitTestWidth,
    this.handleIcon,
    this.handleIconColor = kDefaultHandleIconColor,
    this.handleIconSize = kDefaultHandleIconSize,
    this.handleIconAlignment = Alignment.center,
    this.handleHoverColor = kDefaultHandleHoverColor,
    this.handleActiveColor = kDefaultHandleActiveColor,

    // Animations
    this.sizeDuration = kDefaultSlideDuration,
    this.fadeDuration = kDefaultFadeDuration,
  });

  // --- Panel Styling ---

  /// The vertical padding applied to the top and bottom of the panel header.
  final double headerPadding;

  /// The decoration (background, border) for the panel header.
  final BoxDecoration? headerDecoration;

  /// The text style for the panel title.
  final TextStyle? titleTextStyle;

  /// The default color of the panel icon.
  final Color? iconColor;

  /// The default size of the panel icon.
  final double iconSize;

  /// The decoration (background, border) for the panel content container.
  final BoxDecoration? panelBoxDecoration;

  // --- Rail Styling ---

  /// The decoration (background, border) for the collapsed rail.
  final BoxDecoration? railDecoration;

  /// The total padding around the icon in the rail.
  final double railPadding;

  // --- Resize Handle Styling ---

  /// The color of the resize handle line.
  final Color handleColor;

  /// The visual width of the resize handle line.
  final double handleWidth;

  /// The width of the area that captures mouse events for resizing.
  final double handleHitTestWidth;

  /// The optional icon to display in the resize handle.
  final IconData? handleIcon;

  /// The color of the resize handle icon.
  final Color handleIconColor;

  /// The size of the resize handle icon.
  final double handleIconSize;

  /// The alignment of the icon within the resize handle.
  final Alignment handleIconAlignment;

  /// The color of the resize handle when hovered.
  final Color handleHoverColor;

  /// The color of the resize handle when actively dragged.
  final Color handleActiveColor;

  // --- Animation Defaults ---

  /// The default duration for size change (slide) animations.
  final Duration sizeDuration;

  /// The default duration for opacity change (fade) animations.
  final Duration fadeDuration;

  @override
  List<Object?> get props => [
    headerPadding,
    headerDecoration,
    titleTextStyle,
    iconColor,
    iconSize,
    panelBoxDecoration,
    railDecoration,
    railPadding,
    handleColor,
    handleWidth,
    handleHitTestWidth,
    handleIcon,
    handleIconColor,
    handleIconSize,
    handleIconAlignment,
    handleHoverColor,
    handleActiveColor,
    sizeDuration,
    fadeDuration,
  ];
}

/// An inherited widget that provides [PanelStyle] to its descendants.
class PanelConfigurationScope extends InheritedWidget {
  const PanelConfigurationScope({
    required this.style,
    required super.child,
    super.key,
  });

  final PanelStyle style;

  static PanelStyle of(BuildContext context) {
    final PanelConfigurationScope? result = context
        .dependOnInheritedWidgetOfExactType<PanelConfigurationScope>();
    return result?.style ?? const PanelStyle();
  }

  @override
  bool updateShouldNotify(PanelConfigurationScope oldWidget) =>
      style != oldWidget.style;
}
