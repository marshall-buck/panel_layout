import 'package:flutter/foundation.dart';

/// A flag to enable verbose logging for the panel layout system.
///
/// If true, the layout engine will print detailed measurement and positioning
/// information to the console when running in debug mode.
bool kEnablePanelLayoutLogs = false;

/// Helper function for internal logging.
void panelLayoutLog(String message) {
  if (kDebugMode && kEnablePanelLayoutLogs) {
    debugPrint('[PanelLayout] $message');
  }
}
