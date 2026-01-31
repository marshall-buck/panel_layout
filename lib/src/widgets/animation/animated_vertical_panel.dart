import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import 'dart:math' as math;
import '../../state/panel_runtime_state.dart';
import '../../models/panel_style.dart';
import '../panels/base_panel.dart';

/// A specialized animator for "Vertical" panels (Top/Bottom anchored).
///
/// This widget acts as a wrapper for panels that visually appear as **Top/Bottom Bars**
/// or **Horizontal Strips**. It is named "Vertical" because it animates the
/// panel along the **Vertical Axis** (changing its height).
///
/// Unlike the default animator which cross-fades between a "Panel" and a "Rail",
/// this widget maintains the Header as a persistent element and simply animates
/// the panel's height. This eliminates visual glitching during rotation/collapse.
@internal
class AnimatedVerticalPanel extends StatelessWidget {
  const AnimatedVerticalPanel({
    super.key,
    required this.config,
    required this.state,
    required this.visibilityAnimation,
    required this.collapseAnimation,
  });

  final BasePanel config;
  final PanelRuntimeState state;
  final Animation<double> visibilityAnimation;
  final Animation<double> collapseAnimation;

  @override
  Widget build(BuildContext context) {
    final factor = visibilityAnimation.value;
    final collapseFactor = collapseAnimation.value;

    if (factor <= 0 && !state.visible) {
      return const SizedBox.shrink();
    }

    final layoutConfig = PanelConfigurationScope.of(context);
    final fullSize = state.size;

    // 1. Calculate Durations & Curves
    final fadeDur = config.fadeDuration ?? layoutConfig.fadeDuration;
    final slideDur = config.sizeDuration ?? layoutConfig.sizeDuration;
    final totalMicros =
        (fadeDur > slideDur ? fadeDur : slideDur).inMicroseconds;

    // Avoid div by zero
    final slideEnd = totalMicros == 0
        ? 1.0
        : (slideDur.inMicroseconds / totalMicros).clamp(0.0, 1.0);
    final fadeEnd = totalMicros == 0
        ? 1.0
        : (fadeDur.inMicroseconds / totalMicros).clamp(0.0, 1.0);

    // Default curve is linear if not specified, allowing Interval to handle the pacing.
    final curve = config.animationCurve ?? Curves.linear;

    // Visibility Factors
    final visSlideFactor = Interval(
      0.0,
      slideEnd,
      curve: curve,
    ).transform(factor);
    final visFadeFactor = Interval(
      0.0,
      fadeEnd,
      curve: curve,
    ).transform(factor);

    // Collapse Factors
    // collapseFactor goes 0 -> 1.
    // 0 = Expanded. 1 = Collapsed.
    final colSlideFactor = Interval(
      0.0,
      slideEnd,
      curve: curve,
    ).transform(collapseFactor);
    final colFadeFactor = Interval(
      0.0,
      fadeEnd,
      curve: curve,
    ).transform(collapseFactor);

    // 2. Calculate Sizes
    final effectiveIconSize = config.iconSize ?? layoutConfig.iconSize;
    final effectivePadding = config.headerPadding ?? layoutConfig.headerPadding;
    final headerHeight =
        config.headerHeight ?? (effectiveIconSize + (effectivePadding * 2));

    // Collapsed Size = Header Height (Rail is just the header)
    final collapsedSize = headerHeight;

    // Interpolate Size
    // collapseFactor 0 -> fullSize. 1 -> collapsedSize.
    final currentSize = fullSize + (collapsedSize - fullSize) * colSlideFactor;

    // Apply visibility
    final animatedSize = currentSize * visSlideFactor;

    // 3. Prepare Decoration
    final decoration =
        config.panelBoxDecoration ?? layoutConfig.panelBoxDecoration;

    // 4. Content Opacity
    // Visibility: visFadeFactor (0->1)
    // Collapse: 1 - colFadeFactor (1->0)
    final contentOpacity = (visFadeFactor * (1.0 - colFadeFactor)).clamp(
      0.0,
      1.0,
    );

    return SizedBox(
      height: animatedSize,
      width: double.infinity, // Vertical panels span width
      child: Container(
        decoration: decoration,
        clipBehavior: decoration != null ? Clip.hardEdge : Clip.none,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header: Fixed height, persistent
            Container(
              key: Key('panel_header_${config.id.value}'),
              height: headerHeight,
              decoration:
                  config.headerDecoration ?? layoutConfig.headerDecoration,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: config.buildHeaderRow(context, layoutConfig),
            ),

            // Body: Fills remaining space
            // As animatedSize shrinks to headerHeight, this Expanded widget
            // will naturally shrink to 0.
            Expanded(
              child: _buildContent(contentOpacity, headerHeight),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(double opacity, double headerHeight) {
    Widget content = ClipRect(
      // Clip content so it doesn't overflow visually if it has fixed size inner parts
      child: OverflowBox(
        // Allow content to maintain its logical size (e.g. alignment)
        // while the container shrinks.
        alignment: Alignment.topLeft,
        minHeight: math.max(0.0, state.size - headerHeight), // Use passed headerHeight
        maxHeight: math.max(0.0, state.size - headerHeight),
        // OPTIMIZATION: Wrap content in RepaintBoundary to cache rasterization during animations.
        child: RepaintBoundary(child: config.child),
      ),
    );

    // OPTIMIZATION: Only wrap in Opacity/IgnorePointer if not fully opaque
    if (opacity < 1.0) {
      content = Opacity(
        opacity: opacity,
        child: IgnorePointer(
          ignoring: opacity == 0.0,
          child: content,
        ),
      );
    }

    return content;
  }
}
