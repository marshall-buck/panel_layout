import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';
import '../widgets/base_panel.dart';
import '../widgets/inline_panel.dart';
import '../state/panel_runtime_state.dart';
import '../models/panel_id.dart';

/// A unified data structure for the layout engine.
///
/// It combines the static configuration from [BasePanel] with the
/// dynamic runtime state from [PanelRuntimeState].
@internal
class PanelLayoutData {
  PanelLayoutData({
    required this.config,
    required this.state,
    this.visualFactor = 1.0,
    this.collapseFactor = 0.0,
  });

  /// The static configuration (ID, Anchor, Mode, etc.)
  final BasePanel config;

  /// The dynamic state (current size, visibility, collapse).
  final PanelRuntimeState state;

  /// The current animation factor (0.0 to 1.0) for visibility.
  final double visualFactor;

  /// The current animation factor (0.0 to 1.0) for collapse.
  /// 0.0 = Expanded, 1.0 = Collapsed.
  final double collapseFactor;

  /// Calculated effective size for layout.
  double get effectiveSize {
    // If factor is 0, we take 0 space.
    // If factor is 1, we take full size.
    final baseSize = state.size;
    final collapsedSize =
        config is InlinePanel
            ? (config as InlinePanel).collapsedSize ?? 0.0
            : 0.0;

    // Interpolate between full size and collapsed size based on collapseFactor
    final currentSize = baseSize + (collapsedSize - baseSize) * collapseFactor;

    return currentSize * visualFactor;
  }

  double? get animatedWidth {
    if (config.width == null) return null;
    final base = config.width!;
    final collapsed =
        config is InlinePanel
            ? (config as InlinePanel).collapsedSize ?? 0.0
            : 0.0;
    final current = base + (collapsed - base) * collapseFactor;
    return current * visualFactor;
  }

  double? get animatedHeight {
    if (config.height == null) return null;
    final base = config.height!;
    final collapsed =
        config is InlinePanel
            ? (config as InlinePanel).collapsedSize ?? 0.0
            : 0.0;
    final current = base + (collapsed - base) * collapseFactor;
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
