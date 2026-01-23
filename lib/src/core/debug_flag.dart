import 'package:flutter/foundation.dart';

/// A global flag to enable verbose logging for the panel layout system.
///
/// Set this to `true` in your main function to see detailed output regarding
/// layout calculations, constraints, and panel state changes.
///
/// Example:
/// ```dart
/// void main() {
///   kEnablePanelLayoutLogs = true;
///   runApp(MyApp());
/// }
/// ```
bool kEnablePanelLayoutLogs = false;

/// Helper function for internal logging within the package.
///
/// Logs are only printed if [kDebugMode] is true AND [kEnablePanelLayoutLogs] is true.
void panelLayoutLog(String message) {
  if (kDebugMode && kEnablePanelLayoutLogs) {
    debugPrint('[PanelLayout] $message');
  }
}
