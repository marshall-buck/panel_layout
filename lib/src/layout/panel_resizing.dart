import 'package:meta/meta.dart';
import '../models/panel_id.dart';
import '../state/panel_runtime_state.dart';
import '../widgets/panels/inline_panel.dart';

/// Encapsulates the logic for resizing panels.
@internal
class PanelResizing {
  /// Determines if two adjacent panels can be resized relative to each other.
  static bool canResize(InlinePanel prev, InlinePanel next) {
    // Case 1: Prev is fixed and resizable
    if (prev.flex == null && prev.resizable) return true;

    // Case 2: Next is fixed and resizable
    if (next.flex == null && next.resizable) return true;

    // Case 3: Both are flexible and both are resizable
    if (prev.flex != null &&
        next.flex != null &&
        prev.resizable &&
        next.resizable) {
      return true;
    }

    return false;
  }

  /// Calculates the new sizes for two adjacent panels based on a drag [delta].
  ///
  /// Returns a map of [PanelId] to the new size (width, height, or flex).
  /// If a panel should not change, it is omitted from the map.
  ///
  /// [pixelToFlexRatio] is required for resizing flexible panels (Case 3).
  /// It represents how much [flex] changes for every 1 pixel of size change.
  /// (Calculated as `totalFlex / totalFlexiblePixels`).
  static Map<PanelId, double> calculateResize({
    required double delta,
    required InlinePanel prevConfig,
    required PanelRuntimeState prevState,
    required double prevCollapsedSize,
    required InlinePanel nextConfig,
    required PanelRuntimeState nextState,
    required double nextCollapsedSize,
    double pixelToFlexRatio = 0.0,
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
      if (pixelToFlexRatio <= 0) return changes; // Cannot resize without ratio

      final w1 = prevState.size;
      final w2 = nextState.size;

      // Convert delta (pixels) to deltaFlex
      final deltaFlex = delta * pixelToFlexRatio;

      // Calculate constraints in Flex units
      // Min/Max size are in pixels, so convert them to Flex
      final minFlexPrev = (prevConfig.minSize ?? 0.0) * pixelToFlexRatio;
      final maxFlexPrev = prevConfig.maxSize != null
          ? prevConfig.maxSize! * pixelToFlexRatio
          : double.infinity;

      final minFlexNext = (nextConfig.minSize ?? 0.0) * pixelToFlexRatio;
      final maxFlexNext = nextConfig.maxSize != null
          ? nextConfig.maxSize! * pixelToFlexRatio
          : double.infinity;

      // Apply delta
      var newW1 = w1 + deltaFlex;
      var newW2 = w2 - deltaFlex;

      // Clamp Prev
      if (newW1 < minFlexPrev) {
        final correction = minFlexPrev - newW1;
        newW1 = minFlexPrev;
        newW2 -= correction;
      } else if (newW1 > maxFlexPrev) {
        final correction = newW1 - maxFlexPrev;
        newW1 = maxFlexPrev;
        newW2 += correction;
      }

      // Clamp Next
      if (newW2 < minFlexNext) {
        final correction = minFlexNext - newW2;
        newW2 = minFlexNext;
        newW1 -= correction;
      } else if (newW2 > maxFlexNext) {
        final correction = newW2 - maxFlexNext;
        newW2 = maxFlexNext;
        newW1 += correction;
      }

      changes[prevConfig.id] = newW1.clamp(0.0, double.infinity);
      changes[nextConfig.id] = newW2.clamp(0.0, double.infinity);

      return changes;
    }

    return changes;
  }
}
