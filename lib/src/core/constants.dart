import 'package:flutter/widgets.dart';

// --- Durations ---

/// The duration of the size/slide animation part of the sequence.
const kDefaultSlideDuration = Duration(milliseconds: 250);

/// The duration of the opacity/fade animation part of the sequence.
const kDefaultFadeDuration = Duration(milliseconds: 400);

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

// --- Panel Dimensions & Styling ---

/// The default vertical padding for the panel header (top and bottom).
const kDefaultHeaderPadding = 8.0;

/// The default size of the panel icon (used in header and rail).
const kDefaultIconSize = 24.0;

/// The default total horizontal/vertical padding for the rail around the icon.
const kDefaultRailPadding = 18.0;
