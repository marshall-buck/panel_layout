import 'package:flutter/widgets.dart';
import 'panel_runtime_state.dart';
import '../widgets/base_panel.dart';

/// An inherited widget that exposes the runtime state and configuration of a specific panel.
///
/// Use [PanelDataScope.of] to access the data.
class PanelDataScope extends InheritedModel<String> {
  const PanelDataScope({
    required this.state,
    required this.config,
    required super.child,
    super.key,
  });

  final PanelRuntimeState state;
  final BasePanel config;

  /// Retrieves the closest [PanelDataScope] instance.
  static PanelDataScope? maybeOf(BuildContext context) {
    return InheritedModel.inheritFrom<PanelDataScope>(context);
  }

  /// Retrieves the runtime state from the closest [PanelDataScope].
  static PanelRuntimeState of(BuildContext context) {
    return maybeOf(context)!.state;
  }

  @override
  bool updateShouldNotify(PanelDataScope oldWidget) {
    return state.visible != oldWidget.state.visible ||
        state.collapsed != oldWidget.state.collapsed ||
        state.size != oldWidget.state.size ||
        config != oldWidget.config;
  }

  @override
  bool updateShouldNotifyDependent(
    PanelDataScope oldWidget,
    Set<String> dependencies,
  ) {
    return updateShouldNotify(oldWidget);
  }
}
