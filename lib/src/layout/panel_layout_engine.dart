import 'package:flutter/widgets.dart';
import '../models/panel_id.dart';
import '../models/panel_enums.dart';
import '../widgets/panels/base_panel.dart';
import '../widgets/panels/inline_panel.dart';
import '../widgets/internal/internal_layout_adapter.dart';
import '../widgets/panels/overlay_panel.dart';
import '../state/panel_state_manager.dart';
import '../core/exceptions.dart';
import 'panel_style.dart';
import 'layout_data.dart';


// TODO: Make sure no Time compelxity isues??

/// A pure logic class responsible for calculating layout parameters
/// and preparing data for the [PanelLayout] widget.
class PanelLayoutEngine {
  const PanelLayoutEngine();

  /// Infers the axis from the first [InlinePanel] found in [children].
  ///
  /// Validates that all [InlinePanel]s share the same axis.
  /// Defaults to [Axis.horizontal] if no inline panels are present.
  Axis validateAndComputeAxis(List<BasePanel> children) {
    Axis? axis;
    PanelId? axisEstablishedBy;

    for (final child in children) {
      if (child is InlinePanel && child.anchor != null) {
        final childAxis =
            (child.anchor == PanelAnchor.left ||
                child.anchor == PanelAnchor.right)
            ? Axis.horizontal
            : Axis.vertical;

        if (axis == null) {
          axis = childAxis;
          axisEstablishedBy = child.id;
        } else if (axis != childAxis) {
          throw AnchorException(
            firstPanelId: axisEstablishedBy!,
            firstAxis: axis,
            conflictingPanelId: child.id,
            conflictingAxis: childAxis,
          );
        }
      }
    }
    return axis ?? Axis.horizontal;
  }

  /// Prepares the list of [PanelLayoutData] needed for the layout delegate.
  List<PanelLayoutData> createLayoutData({
    required Map<PanelId, BasePanel> uniquePanelConfigs,
    required PanelStyle config,
    required PanelStateManager stateManager,
  }) {
    return uniquePanelConfigs.values.map((panelConfig) {
      final state = stateManager.getState(panelConfig.id)!;
      final anim = stateManager.getAnimationController(panelConfig.id)!;
      final collapseAnim = stateManager.getCollapseController(panelConfig.id)!;

      double collapsedSize = 0.0;
      if (panelConfig is InlinePanel) {
        final iconSize = panelConfig.iconSize ?? config.iconSize;
        collapsedSize =
            iconSize + (panelConfig.railPadding ?? config.railPadding);
      }

      return PanelLayoutData(
        config: panelConfig,
        state: state,
        visualFactor: anim.value,
        collapseFactor: collapseAnim.value,
        collapsedSize: collapsedSize,
      );
    }).toList();
  }

  /// Calculates the ratio between pixels and flex units.
  ///
  /// This is essential for resizing flexible panels, as it allows converting
  /// drag deltas (pixels) into flex value changes.
  double calculatePixelToFlexRatio({
    required List<PanelLayoutData> layoutData,
    required BoxConstraints constraints,
    required Axis axis,
    required PanelStyle config,
  }) {
    final totalSpace = axis == Axis.horizontal
        ? constraints.maxWidth
        : constraints.maxHeight;

    double usedPixelSpace = 0.0;
    double totalFlex = 0.0;

    for (final data in layoutData) {
      if (data.config is! InlinePanel) continue;

      if (!data.state.visible && data.visualFactor <= 0) continue;

      // TODO: Lets maek suere all prop names are diferetiang betwenn flutter's flex and the package's flex.

      final flex = data.config is InternalLayoutAdapter
          ? (data.config as InternalLayoutAdapter).flex
          : null;

      if (flex == null) {
        // Fixed panel (or collapsed fixed/flex)
        // effectiveSize handles interpolation for collapse and visibility
        usedPixelSpace += data.effectiveSize;
      } else {
        // Flexible panel
        if (data.state.collapsed) {
          // If a flex panel is collapsed, it acts as fixed pixels (rail)
          usedPixelSpace += data.effectiveSize;
        } else {
          // Normal flexible panel
          // effectiveSize for flex panel returns its weighted flex?
          // InlineLayoutStrategy uses effectiveSize for flex weight.
          // So we should use effectiveSize here too if we want to support animated flex?
          // But usually flex doesn't animate via effectiveSize logic?
          // PanelLayoutData.effectiveSize:
          // base = state.size (flex).
          // current = base + (collapsed - base) * factor.
          // If factor > 0 (collapsing), it returns interpolation.
          // BUT calculatePixelToFlexRatio separates UsedPixels vs TotalFlex.
          // If it is collapsing, it is transitioning from Flex to Pixels.
          // This is hard to model with simple ratio.
          // But for Stability test (Fixed panel collapsing), this branch (Flex) is for neighbors.
          // Neighbors are NOT collapsing.
          // So state.collapsed is false.
          // So we add to totalFlex.
          // We should use state.size (Flex factor).
          // effectiveSize for Flex panel = state.size * visualFactor.
          // If visualFactor < 1 (fading in/out), its weight is reduced.
          // Yes, we should use effectiveSize for TotalFlex too!
          totalFlex += data.effectiveSize;
        }
      }
    }

    // Add Resize Handles to used space
    final dockedPanels = layoutData
        .where((d) => d.config is InlinePanel)
        .toList();
    int visibleHandleCount = 0;
    for (var i = 0; i < dockedPanels.length - 1; i++) {
      final prev = dockedPanels[i];
      final next = dockedPanels[i + 1];
      if ((prev.state.visible || prev.visualFactor > 0) &&
          (next.state.visible || next.visualFactor > 0)) {
        visibleHandleCount++;
      }
    }
    usedPixelSpace += visibleHandleCount * config.handleHitTestWidth;

    final flexibleSpace = totalSpace - usedPixelSpace;
    return (flexibleSpace > 0 && totalFlex > 0)
        ? totalFlex / flexibleSpace
        : 0.0;
  }

  /// Calculates the new flex factor for a panel that is being unlocked
  /// (transitioning from a fixed pixel override back to flexible sizing).
  double calculateNewFlexForUnlockedPanel({
    required List<PanelLayoutData> layoutData,
    required PanelId targetPanelId,
    required double targetPixels,
    required BoxConstraints constraints,
    required Axis axis,
    required PanelStyle config,
  }) {
    final totalSpace = axis == Axis.horizontal
        ? constraints.maxWidth
        : constraints.maxHeight;

    double usedPixelSpace = 0.0;
    double totalFlexOthers = 0.0;

    final dockedPanels = layoutData
        .where((d) => d.config is InlinePanel)
        .toList();

    for (final data in dockedPanels) {
      if (!data.state.visible && data.visualFactor <= 0) continue;

      if (data.config.id == targetPanelId) {
        // This is the one we are unlocking.
        // It contributes 0 to usedPixelSpace and 0 to totalFlexOthers (temporarily).
      } else if (data.state.collapsed) {
        usedPixelSpace += data.collapsedSize;
      } else {
        final flex = data.config is InternalLayoutAdapter
            ? (data.config as InternalLayoutAdapter).flex
            : null;
        if (flex == null) {
          // Fixed panel
          usedPixelSpace += data.effectiveSize;
        } else {
          // Flex (Other)
          if (data.state.fixedPixelSizeOverride != null) {
            usedPixelSpace += data.state.fixedPixelSizeOverride!;
          } else {
            totalFlexOthers += data.effectiveSize;
          }
        }
      }
    }

    // Add handles
    int visibleHandleCount = 0;
    for (var i = 0; i < dockedPanels.length - 1; i++) {
      final prev = dockedPanels[i];
      final next = dockedPanels[i + 1];
      if ((prev.state.visible || prev.visualFactor > 0) &&
          (next.state.visible || next.visualFactor > 0)) {
        visibleHandleCount++;
      }
    }
    usedPixelSpace += visibleHandleCount * config.handleHitTestWidth;

    final flexibleSpace = totalSpace - usedPixelSpace;

    // Retrieve the target panel's current flex from state (as fallback/reference)
    final targetData = layoutData.firstWhere(
      (d) => d.config.id == targetPanelId,
      orElse: () => layoutData.first,
    );
    final targetFlex = targetData.config is InternalLayoutAdapter
        ? (targetData.config as InternalLayoutAdapter).flex
        : 1.0;

    if (totalFlexOthers <= 0) {
      // No other flex panels. Target takes all space.
      return targetData
          .state
          .size; // Or targetFlex? Original used state.size or default.
    }

    if (flexibleSpace <= targetPixels) {
      // Not enough space. Return large flex.
      return targetFlex * 2;
    }

    // Equation: F_target = (pixels * F_others) / (Available - pixels)
    final numerator = targetPixels * totalFlexOthers;
    final denominator = flexibleSpace - targetPixels;

    if (denominator <= 0.1) {
      return 100.0; // Avoid div by zero
    }

    return numerator / denominator;
  }

  /// Sorts children to ensure correct painting order (z-index).
  List<Widget> sortChildren({
    required List<Widget> unsorted,
    required Map<PanelId, BasePanel> configs,
  }) {
    final List<Widget> sorted = List.from(unsorted);
    sorted.sort((a, b) {
      final idA = (a as LayoutId).id;
      final idB = (b as LayoutId).id;

      int zA = 0;
      if (idA is PanelId) {
        final config = configs[idA];
        if (config is OverlayPanel) zA = config.zIndex;
      }

      int zB = 0;
      if (idB is PanelId) {
        final config = configs[idB];
        if (config is OverlayPanel) zB = config.zIndex;
      }

      if (zA != zB) return zA.compareTo(zB);

      return unsorted.indexOf(a).compareTo(unsorted.indexOf(b));
    });

    return sorted;
  }
}
