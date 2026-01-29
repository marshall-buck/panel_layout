import 'package:meta/meta.dart';
import '../models/panel_id.dart';
import '../state/panel_runtime_state.dart';
import '../widgets/panels/inline_panel.dart';
import '../widgets/internal/internal_layout_adapter.dart';

/// Encapsulates the logic for resizing panels.
@internal
class PanelResizing {
  /// Determines if two adjacent panels can be resized relative to each other.
  static bool canResize(InlinePanel prev, InlinePanel next) {
    final prevWeight = prev is InternalLayoutAdapter ? prev.layoutWeight : null;
    final nextWeight = next is InternalLayoutAdapter ? next.layoutWeight : null;

    // Case 1: Prev is fixed and resizable
    if (prevWeight == null && prev.resizable) return true;

    // Case 2: Next is fixed and resizable
    if (nextWeight == null && next.resizable) return true;

    // Case 3: Both are flexible and both are resizable
    if (prevWeight != null &&
        nextWeight != null &&
        prev.resizable &&
        next.resizable) {
      return true;
    }

    return false;
  }

  /// Calculates the new sizes for two adjacent panels based on a drag [delta].
  ///
  /// Returns a map of [PanelId] to the new size (width, height, or weight).
  /// If a panel should not change, it is omitted from the map.
  ///
  /// [pixelToWeightRatio] is required for resizing weighted panels (Case 3).
  /// It represents how much [layoutWeight] changes for every 1 pixel of size change.
  /// (Calculated as `totalWeight / totalWeightedPixels`).
  static Map<PanelId, double> calculateResize({
    required double delta,
    required InlinePanel prevConfig,
    required PanelRuntimeState prevState,
    required double prevCollapsedSize,
    required InlinePanel nextConfig,
    required PanelRuntimeState nextState,
    required double nextCollapsedSize,
    double pixelToWeightRatio = 0.0,
  }) {
    final changes = <PanelId, double>{};
    final prevWeight =
        prevConfig is InternalLayoutAdapter ? prevConfig.layoutWeight : null;
    final nextWeight =
        nextConfig is InternalLayoutAdapter ? nextConfig.layoutWeight : null;

    // Case 1: Prev is fixed, Next is whatever. Resize Prev.
    if (prevWeight == null && prevConfig.resizable) {
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

      // Isolation: If Next is Weighted, it must absorb the delta to prevent global shift
      if (nextWeight != null && pixelToWeightRatio > 0) {
         final actualDelta = newSize - prevState.size;
         final deltaWeight = actualDelta * pixelToWeightRatio;
         // Weighted panels can theoretically go to 0 or very small
         final newWeight = (nextState.size - deltaWeight).clamp(0.0, double.infinity);
         changes[nextConfig.id] = newWeight;
      }

      return changes;
    }

    // Case 2: Prev is weighted (or not resizable), Next is fixed. Resize Next (inverse).
    if (nextWeight == null && nextConfig.resizable) {
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

      // Isolation: If Prev is Weighted, it must absorb the delta to prevent global shift
      if (prevWeight != null && pixelToWeightRatio > 0) {
        final actualDelta = nextState.size - newSize; // Positive if next shrank
        final deltaWeight = actualDelta * pixelToWeightRatio;
        // If next shrank (dragged right), actualDelta is positive, Prev grows.
        // If next grew (dragged left), actualDelta is negative, Prev shrinks.
        final newWeight = (prevState.size + deltaWeight).clamp(0.0, double.infinity);
        changes[prevConfig.id] = newWeight;
      }

      return changes;
    }

    // Case 3: Both are flexible. Adjust weights.
    if (prevWeight != null &&
        nextWeight != null &&
        prevConfig.resizable &&
        nextConfig.resizable) {
      if (prevState.collapsed || nextState.collapsed) return changes;
      if (pixelToWeightRatio <= 0) return changes; // Cannot resize without ratio

      final w1 = prevState.size;
      final w2 = nextState.size;

      // Convert delta (pixels) to deltaWeight
      final deltaWeight = delta * pixelToWeightRatio;

      // Calculate constraints in Weight units
      // Min/Max size are in pixels, so convert them to Weight
      final minWeightPrev = (prevConfig.minSize ?? 0.0) * pixelToWeightRatio;
      final maxWeightPrev = prevConfig.maxSize != null
          ? prevConfig.maxSize! * pixelToWeightRatio
          : double.infinity;

      final minWeightNext = (nextConfig.minSize ?? 0.0) * pixelToWeightRatio;
      final maxWeightNext = nextConfig.maxSize != null
          ? nextConfig.maxSize! * pixelToWeightRatio
          : double.infinity;

      // Apply delta
      var newW1 = w1 + deltaWeight;
      var newW2 = w2 - deltaWeight;

      // Clamp Prev
      if (newW1 < minWeightPrev) {
        final correction = minWeightPrev - newW1;
        newW1 = minWeightPrev;
        newW2 -= correction;
      } else if (newW1 > maxWeightPrev) {
        final correction = newW1 - maxWeightPrev;
        newW1 = maxWeightPrev;
        newW2 += correction;
      }

      // Clamp Next
      if (newW2 < minWeightNext) {
        final correction = minWeightNext - newW2;
        newW2 = minWeightNext;
        newW1 -= correction;
      } else if (newW2 > maxWeightNext) {
        final correction = newW2 - maxWeightNext;
        newW2 = maxWeightNext;
        newW1 += correction;
      }

      changes[prevConfig.id] = newW1.clamp(0.0, double.infinity);
      changes[nextConfig.id] = newW2.clamp(0.0, double.infinity);

      return changes;
    }

    return changes;
  }
}
