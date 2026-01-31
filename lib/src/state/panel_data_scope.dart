import 'package:flutter/widgets.dart';
import 'panel_runtime_state.dart';
import '../widgets/panels/base_panel.dart';

/// An inherited widget that exposes the runtime state and configuration of a specific panel.
///
/// This widget is automatically injected by [PanelArea] for each of its children.
/// Use [PanelDataScope.of] within a custom panel builder to access data like
/// current size, visibility, or collapse state.
///
/// This is useful if you want your panel content to react to its own state
/// (e.g., showing a different widget when collapsed).
class PanelDataScope extends InheritedModel<String> {
  const PanelDataScope({
    required this.state,
    required this.config,
    required super.child,
    super.key,
  });

  /// The dynamic runtime state of the panel (size, visibility, etc.).
  final PanelRuntimeState state;

  /// The static configuration of the panel (ID, initial settings).
  final BasePanel config;

  /// Retrieves the closest [PanelDataScope] instance.
  static PanelDataScope? maybeOf(BuildContext context) {
    return InheritedModel.inheritFrom<PanelDataScope>(context);
  }

  /// Retrieves the runtime state from the closest [PanelDataScope].
  ///
  /// Throws an error if no scope is found.
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
