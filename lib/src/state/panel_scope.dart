import 'package:flutter/widgets.dart';

import '../controllers/panel_area_controller.dart';

/// An inherited widget that exposes the [PanelAreaController] to the widget tree.
///
/// This allows any descendant widget to control the layout (e.g., toggle panels)
/// without needing the controller passed down explicitly.
///
/// Use [PanelArea.of] or [PanelScope.of] to access the controller.
class PanelScope extends InheritedWidget {
  /// Creates a [PanelScope].
  const PanelScope({required this.controller, required super.child, super.key});

  /// The layout controller being exposed.
  final PanelAreaController controller;

  /// Retrieves the [PanelAreaController] from the closest [PanelScope] ancestor.
  ///
  /// [listen] determines whether the context should rebuild when the *controller instance* changes
  /// (which is rare). To listen to panel state changes, use a [ListenableBuilder]
  /// on the returned controller or specific [PanelController]s.
  static PanelAreaController of(BuildContext context, {bool listen = true}) {
    final PanelScope? scope;
    if (listen) {
      scope = context.dependOnInheritedWidgetOfExactType<PanelScope>();
    } else {
      scope = context.getInheritedWidgetOfExactType<PanelScope>();
    }

    if (scope == null) {
      throw Exception(
        'PanelScope not found in context. '
        'Ensure that the widget tree is wrapped in a PanelArea.',
      );
    }
    return scope.controller;
  }

  @override
  bool updateShouldNotify(PanelScope oldWidget) =>
      controller != oldWidget.controller;
}
