import 'package:meta/meta.dart';
import '../models/panel_id.dart';
import '../state/panel_runtime_state.dart';
import '../widgets/panels/inline_panel.dart';

/// Encapsulates the logic for resizing panels.
@internal
class PanelResizing {
  /// Calculates the new sizes for two adjacent panels based on a drag [delta].
  ///
  /// Returns a map of [PanelId] to the new size (width, height, or flex).
  /// If a panel should not change, it is omitted from the map.
  static Map<PanelId, double> calculateResize({
    required double delta,
    required InlinePanel prevConfig,
    required PanelRuntimeState prevState,
    required double prevCollapsedSize,
    required InlinePanel nextConfig,
    required PanelRuntimeState nextState,
    required double nextCollapsedSize,
  }) {
    final changes = <PanelId, double>{};

    // Case 1: Prev is fixed, Next is whatever. Resize Prev.
    if (prevConfig.flex == null && prevConfig.resizable) {
      if (prevState.collapsed) return changes;

      final minSize = prevConfig.minSize ?? 0.0;
      final effectiveMin = minSize < prevCollapsedSize
          ? prevCollapsedSize
          : minSize;

      final newSize = (prevState.size + delta).clamp(
        effectiveMin,
        prevConfig.maxSize ?? double.infinity,
      );
      changes[prevConfig.id] = newSize;
      return changes;
    }

    // Case 2: Prev is flex (or not resizable), Next is fixed. Resize Next (inverse).
    if (nextConfig.flex == null && nextConfig.resizable) {
      if (nextState.collapsed) return changes;

      final minSize = nextConfig.minSize ?? 0.0;
      final effectiveMin = minSize < nextCollapsedSize
          ? nextCollapsedSize
          : minSize;

      final newSize = (nextState.size - delta).clamp(
        effectiveMin,
        nextConfig.maxSize ?? double.infinity,
      );
      changes[nextConfig.id] = newSize;
      return changes;
    }

    // Case 3: Both are flexible. Adjust flex weights.
    if (prevConfig.flex != null &&
        nextConfig.flex != null &&
        prevConfig.resizable &&
        nextConfig.resizable) {
      if (prevState.collapsed || nextState.collapsed) return changes;

      final w1 = prevState.size;
      final w2 = nextState.size;

      const sensitivity = 0.01;

      changes[prevConfig.id] = (w1 + delta * sensitivity).clamp(
        0.0,
        double.infinity,
      );
      changes[nextConfig.id] = (w2 - delta * sensitivity).clamp(
        0.0,
        double.infinity,
      );

      return changes;
    }

    return changes;
  }
}
