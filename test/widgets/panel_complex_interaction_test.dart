import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_panels/flutter_panels.dart';

void main() {
  group('Complex Interaction & Performance Tests', () {
    testWidgets('Resizing while Animating: Neighbor remains locked', (
      tester,
    ) async {
      // This test verifies that if we start a resize while another panel is animating,
      // the locking logic doesn't oscillate or cause crashes.
      final controller = PanelAreaController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PanelArea(
              controller: controller,
              children: [
                // Neighbor (index 0)
                const SizedBox.expand(
                  child: Text('B', key: Key('neighbor_child')),
                ),
                // Animating Panel (index 1), anchored to the left (towards B)
                InlinePanel(
                  id: const PanelId('animating'),
                  anchor: PanelAnchor.left,
                  width: 200,
                  child: const Text('A'),
                ),
              ],
            ),
          ),
        ),
      );

      final neighborFinder = find.byKey(const Key('neighbor_child'));
      final initialWidth = tester.getSize(neighborFinder).width;

      // 1. Start Animation
      controller.setVisible(const PanelId('animating'), false);
      await tester.pump(); // Status: Reverse (Starting)
      await tester.pump(const Duration(milliseconds: 100)); // Mid-animation

      // Neighbor should be LOCKED to its initial width
      expect(
        tester.getSize(neighborFinder).width,
        moreOrLessEquals(initialWidth, epsilon: 0.1),
      );

      // 2. Trigger a Resize on the neighbor while animation is active
      // (This simulates a user trying to drag while things are moving)
      // Note: We don't have a handle for the animating panel's edge easily,
      // but we can manually update the size via controller.
      controller.updateSize(const PanelId('auto_panel_0'), initialWidth + 50);
      await tester.pump();

      // The neighbor should accept the update but stay "stable" relative to the animating panel.
      // Actually, if it's locked to Pixels, updateSize (which updates Weights) should be
      // reflected in the state but the OVERRIDE should still be active?
      // Our logic: _lockNeighbor sets fixedPixelSizeOverride.
      // InlineLayoutStrategy uses override if present.
      // So neighbor should STAY at initialWidth even if weight changed in state.

      expect(
        tester.getSize(neighborFinder).width,
        moreOrLessEquals(initialWidth, epsilon: 0.1),
      );

      // 3. Finish Animation
      await tester.pumpAndSettle();

      // Now it should unlock and apply the new size (initial + 50)
      expect(tester.getSize(neighborFinder).width, greaterThan(initialWidth));
    });

    testWidgets('Concurrent Animations: Multiple panels opening/closing', (
      tester,
    ) async {
      final controller = PanelAreaController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PanelArea(
              controller: controller,
              children: [
                InlinePanel(
                  id: const PanelId('left'),
                  anchor: PanelAnchor.left,
                  width: 100,
                  initialVisible: false,
                  child: const Text('L'),
                ),
                const InlinePanel(id: PanelId('main'), child: Text('M')),
                InlinePanel(
                  id: const PanelId('right'),
                  anchor: PanelAnchor.right,
                  width: 100,
                  initialVisible: false,
                  child: const Text('R'),
                ),
              ],
            ),
          ),
        ),
      );

      // Trigger both
      controller.setVisible(const PanelId('left'), true);
      controller.setVisible(const PanelId('right'), true);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('L'), findsOneWidget);
      expect(find.text('R'), findsOneWidget);

      // Verify no crashes and layout is progressing
      await tester.pumpAndSettle();

      expect(tester.getSize(find.text('L')).width, 100);
      expect(tester.getSize(find.text('R')).width, 100);
    });

    testWidgets('Z-Order Stability during animation', (tester) async {
      final controller = PanelAreaController();
      final link = LayerLink();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PanelArea(
              controller: controller,
              children: [
                InlinePanel(
                  id: const PanelId('left'),
                  anchor: PanelAnchor.left,
                  width: 100,
                  child: CompositedTransformTarget(
                    link: link,
                    child: const Text('Target'),
                  ),
                ),
                OverlayPanel(
                  id: const PanelId('overlay'),
                  anchorLink: link,
                  width: 50,
                  height: 50,
                  zIndex: 100,
                  child: const Text('Overlay'),
                ),
              ],
            ),
          ),
        ),
      );

      // Toggle Left panel
      controller.setVisible(const PanelId('left'), false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Overlay should follow the target even during animation
      expect(find.text('Overlay'), findsOneWidget);

      await tester.pumpAndSettle();
    });
  });
}
