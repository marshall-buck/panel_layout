import 'package:flutter/widgets.dart';

// --- Durations ---

/// The default duration for panel animations (expansion, collapse, visibility changes).
const kDefaultAnimationDuration = Duration(milliseconds: 250);

/// The default duration for hover effects on resize handles.
const kDefaultHoverDuration = Duration(milliseconds: 150);

// --- Handle Dimensions ---

/// The default visual width (or height, depending on axis) of the resize handle line.
const kDefaultHandleWidth = 4.0;

/// The default width (or height) of the invisible hit-test area for resizing.
/// This allows users to grab the handle easily without requiring a thick visual line.
const kDefaultHandleHitTestWidth = 8.0;

/// The default size for the optional icon within the resize handle.
const kDefaultHandleIconSize = 4.0;

// --- Colors (Neutral Defaults) ---

/// The default color of the resize handle line.
const kDefaultHandleColor = Color(0x33000000); // Transparent black

/// The default color of the resize handle when hovered.
const kDefaultHandleHoverColor = Color(0x66000000);

/// The default color of the resize handle when actively dragged.
const kDefaultHandleActiveColor = Color(0x99000000);

/// The default color of the resize handle icon.
const kDefaultHandleIconColor = Color(0xAA000000);