import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import '../core/debug_flag.dart';
import 'layout_data.dart';
import 'strategies/layout_context.dart';
import 'strategies/inline_layout_strategy.dart';
import 'strategies/overlay_layout_strategy.dart';

/// A delegate that calculates the layout of panels based on [PanelLayoutData].
///
/// This is the "brain" of the layout engine, responsible for positioning
/// inline and overlay panels according to their anchors and sizes.
///
/// It delegates the actual calculation to:
/// - [InlineLayoutStrategy] for the grid/flex layout.
/// - [OverlayLayoutStrategy] for floating panels.
@internal
class PanelLayoutDelegate extends MultiChildLayoutDelegate
    implements LayoutContext {
  PanelLayoutDelegate({
    required this.panels,
    required this.axis,
    required this.textDirection,
  });

  /// The list of all panels to be laid out.
  final List<PanelLayoutData> panels;

  /// The main axis of the layout (Horizontal = Row-like, Vertical = Column-like).
  final Axis axis;

  /// The text direction (for RTL support).
  final TextDirection textDirection;

  @override
  void performLayout(Size size) {
    panelLayoutLog('Delegate performLayout with ${panels.length} panels');

    final inlineStrategy = InlineLayoutStrategy();
    final inlineRects = inlineStrategy.layout(
      context: this,
      size: size,
      panels: panels,
      axis: axis,
    );

    final overlayStrategy = OverlayLayoutStrategy();
    overlayStrategy.layout(
      context: this,
      size: size,
      panels: panels,
      inlineRects: inlineRects,
      textDirection: textDirection,
    );
  }

  @override
  bool shouldRelayout(PanelLayoutDelegate oldDelegate) {
    // In the engine, we'll re-create the delegate if the configuration or state changes.
    return true;
  }
}
