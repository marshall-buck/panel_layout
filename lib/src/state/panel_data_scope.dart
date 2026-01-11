import 'package:flutter/widgets.dart';
import 'panel_runtime_state.dart';

/// An inherited widget that exposes the runtime state of a specific panel.
///
/// Use [PanelDataScope.of] to access the state (e.g., to check if collapsed).
class PanelDataScope extends InheritedModel<String> {
  const PanelDataScope({
    required this.state,
    required super.child,
    super.key,
  });

  final PanelRuntimeState state;

  /// Retrieves the runtime state from the closest [PanelDataScope].
  static PanelRuntimeState of(BuildContext context) {
    return InheritedModel.inheritFrom<PanelDataScope>(context)!.state;
  }

  @override
  bool updateShouldNotify(PanelDataScope oldWidget) {
    return state.visible != oldWidget.state.visible ||
           state.collapsed != oldWidget.state.collapsed ||
           state.size != oldWidget.state.size;
  }

  @override
  bool updateShouldNotifyDependent(PanelDataScope oldWidget, Set<String> dependencies) {
    return updateShouldNotify(oldWidget);
  }
}
