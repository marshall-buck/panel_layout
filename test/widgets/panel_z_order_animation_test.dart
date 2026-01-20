import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/panel_layout.dart';
import 'package:panel_layout/src/widgets/animated_panel.dart';

void main() {
  testWidgets(
    'Overlay panel anchored to Left of Right-Inline panel animates from behind',
    (tester) async {
      final controller = PanelLayoutController();
      const animationDuration = Duration(milliseconds: 200);

      // We define the Overlay BEFORE the Inline panel in the list.
      // This ensures the Overlay is painted first (behind) the Inline panel.
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PanelTheme(
            data: const PanelThemeData(
              // No decoration to simplify hit/paint checks, or distinct colors
            ),
            child: SizedBox(
              width: 800,
              height: 600,
              child: PanelLayout(
                controller: controller,
                children: [
                  // Widget B: The Overlay that should be BEHIND
                  // We explicitly set Z-Index to -1 to be sure, or rely on list order.
                  // Relying on list order (default behavior):
                  OverlayPanel(
                    id: const PanelId('overlay_behind'),
                    anchorTo: const PanelId('inline_front'),
                    anchor: PanelAnchor.left,
                    width: 200,
                    initialVisible: false, // Start hidden
                    child: Container(color: Colors.red),
                  ),

                  // Spacer to push the Right panel to the right side
                  InlinePanel(
                    id: const PanelId('spacer'),
                    flex: 1,
                    child: const SizedBox(),
                  ),

                  // Widget A: The Inline Panel in FRONT
                  InlinePanel(
                    id: const PanelId('inline_front'),
                    anchor: PanelAnchor.right,
                    width: 300,
                    child: Container(color: Colors.blue),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Initial State:
      // Inline Panel should be at Right (800 - 300 = 500)
      final inlineFinder = find.byWidgetPredicate(
        (w) => w is InlinePanel && w.id == const PanelId('inline_front'),
      );
      final inlineRectInitial = tester.getRect(inlineFinder);
      expect(inlineRectInitial.left, 500.0);
      expect(inlineRectInitial.width, 300.0);

      // Overlay should be hidden (width 0)
      final overlayAnimatedPanelFinder = find.byWidgetPredicate(
        (w) =>
            w is AnimatedPanel &&
            w.config.id == const PanelId('overlay_behind'),
      );
      expect(tester.getSize(overlayAnimatedPanelFinder).width, 0.0);

      // ACTION: Open the Overlay
      controller.setVisible(const PanelId('overlay_behind'), true);
      await tester.pump(); // Start animation

      // CHECK: Mid-animation (e.g. 50%)
      await tester.pump(animationDuration ~/ 2);

      final overlayRect = tester.getRect(overlayAnimatedPanelFinder);
      final inlineRect = tester.getRect(inlineFinder);

      // 1. Verify Overlay is attached to the Left of Inline
      // The Overlay's Right edge should roughly equal Inline's Left edge
      // (Allowing for small double precision or pixel snapping diffs)
      expect(overlayRect.right, closeTo(inlineRect.left, 0.5));

      // 2. Verify Overlay is growing to the Left
      // Width should be somewhere between 0 and 200.
      // 80.0 was observed with default curve at 50%, which is fine.
      expect(overlayRect.width, greaterThan(10.0));
      expect(overlayRect.width, lessThan(190.0));

      // Verify the Overlay's left edge is roughly (InlineLeft - currentWidth)
      expect(
        overlayRect.left,
        closeTo(inlineRect.left - overlayRect.width, 1.0),
      );

      // CHECK: End of animation
      await tester.pumpAndSettle();

      final finalOverlayRect = tester.getRect(overlayAnimatedPanelFinder);
      expect(finalOverlayRect.width, 200.0);
      expect(finalOverlayRect.right, closeTo(inlineRect.left, 0.1));
      expect(finalOverlayRect.left, closeTo(300.0, 0.1)); // 500 - 200
    },
  );
}
