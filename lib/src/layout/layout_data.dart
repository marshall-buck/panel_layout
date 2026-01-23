import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import '../widgets/panels/base_panel.dart';
import '../state/panel_runtime_state.dart';
import '../models/panel_id.dart';

/// A unified data structure used by the [PanelLayoutDelegate].
///
/// It combines the static configuration from [BasePanel] with the
/// dynamic runtime state from [PanelRuntimeState], along with current animation values.
///
/// This class acts as the "snapshot" of a panel for a single layout pass.
@internal
class PanelLayoutData {
  PanelLayoutData({
    required this.config,
    required this.state,
    this.visualFactor = 1.0,
    this.collapseFactor = 0.0,
    required this.collapsedSize,
  });

  /// The static configuration (ID, Anchor, Mode, etc.)
  final BasePanel config;

  /// The dynamic state (current size, visibility, collapse).
  final PanelRuntimeState state;

  /// The current animation factor (0.0 to 1.0) for visibility.
  /// 1.0 = Fully Visible, 0.0 = Hidden.
  final double visualFactor;

  /// The current animation factor (0.0 to 1.0) for collapse.
  /// 0.0 = Expanded, 1.0 = Collapsed.
  final double collapseFactor;

  /// The calculated size of the panel when collapsed (rail size).
  final double collapsedSize;

  /// Calculated effective size for layout.
  ///
  /// Takes into account the current size (or flex) and interpolates it
  /// based on the [collapseFactor]. If the panel is collapsing, it shrinks
  /// towards the rail size.
  double get effectiveSize {
    // If factor is 0, we take 0 space.
    // If factor is 1, we take full size.
    final baseSize = state.size;

    // Interpolate between full size and collapsed size based on collapseFactor
    final currentSize = baseSize + (collapsedSize - baseSize) * collapseFactor;

    return currentSize * visualFactor;
  }

  /// The width to use for animation purposes (for Overlay panels).
  double? get animatedWidth {
    if (config.width == null) return null;
    final base = config.width!;
    final current = base + (collapsedSize - base) * collapseFactor;
    return current * visualFactor;
  }

  /// The height to use for animation purposes (for Overlay panels).
  double? get animatedHeight {
    if (config.height == null) return null;
    final base = config.height!;
    final current = base + (collapsedSize - base) * collapseFactor;
    return current * visualFactor;
  }
}

/// A unique identifier for a resize handle between two panels.
@internal
class HandleLayoutId extends Equatable {
  const HandleLayoutId(this.previousPanelId, this.nextPanelId);

  final PanelId previousPanelId;
  final PanelId nextPanelId;

  @override
  List<Object?> get props => [previousPanelId, nextPanelId];
}
