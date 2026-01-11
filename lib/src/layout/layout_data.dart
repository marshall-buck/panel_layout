import 'package:equatable/equatable.dart';
import '../widgets/base_panel.dart';
import '../state/panel_runtime_state.dart';
import '../models/panel_id.dart';

/// A unified data structure for the layout engine.
///
/// It combines the static configuration from [BasePanel] with the
/// dynamic runtime state from [PanelRuntimeState].
class PanelLayoutData {
  PanelLayoutData({
    required this.config,
    required this.state,
  });

  /// The static configuration (ID, Anchor, Mode, etc.)
  final BasePanel config;

  /// The dynamic state (current size, visibility, collapse).
  final PanelRuntimeState state;

  /// Calculated effective size for layout.
  double get effectiveSize {
    if (!state.visible) return 0.0;
    if (state.collapsed) return config.collapsedSize ?? 0.0;
    return state.size;
  }
}

/// A unique identifier for a resize handle between two panels.
class HandleLayoutId extends Equatable {
  const HandleLayoutId(this.previousPanelId, this.nextPanelId);

  final PanelId previousPanelId;
  final PanelId nextPanelId;

  @override
  List<Object?> get props => [previousPanelId, nextPanelId];
}
