import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/panel_layout.dart';

void main() {
  const panelA = PanelId('panelA');
  const panelB = PanelId('panelB');

  group('Overlay Animation Direction', () {
    testWidgets('Global Left Anchor slides from Left (-1, 0)', (tester) async {
      final controller = PanelLayoutController();
      controller.registerPanel(
        panelA,
        builder: (context, _) => SizedBox(width: 100, height: 100),
        sizing: const FixedSizing(100),
        mode: PanelMode.overlay,
        anchor: PanelAnchor.left,
        isVisible: false,
        visuals: const PanelVisuals(animationDuration: Duration(seconds: 1)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PanelScope(
            controller: controller,
            child: PanelArea(
              panelLayoutController: controller,
              panelIds: const [panelA],
            ),
          ),
        ),
      );

      // Show panel
      controller.getPanel(panelA)!.setVisible(visible: true);
      await tester.pump(); // Start animation
      await tester.pump(const Duration(milliseconds: 10)); // Advance slightly

      // Find the SlideTransition wrapping the visible content
      final contentKey = ValueKey('panel_${panelA.value}_visible');
      final slideFinder = find.ancestor(
        of: find.byKey(contentKey),
        matching: find.byType(SlideTransition),
      );

      final slideTransition = tester.firstWidget<SlideTransition>(slideFinder);
      final offset = slideTransition.position.value;

      // Expect to be close to (-1, 0) moving towards (0, 0)
      expect(offset.dx, lessThan(0));
      expect(offset.dx, greaterThan(-1.1));
    });

    testWidgets('Relative Left Anchor (to Target) slides from Right (+1, 0)', (
      tester,
    ) async {
      final controller = PanelLayoutController();

      // Target
      controller.registerPanel(
        panelA,
        builder: (context, _) => SizedBox(width: 100, height: 100),
        sizing: const FixedSizing(100),
        mode: PanelMode.inline,
        anchor: PanelAnchor.right,
      );

      // Overlay anchored to Target (Left of Target)
      controller.registerPanel(
        panelB,
        builder: (context, _) => SizedBox(width: 100, height: 100),
        sizing: const FixedSizing(100),
        mode: PanelMode.overlay,
        anchor: PanelAnchor.left,
        anchorPanel: panelA,
        isVisible: false,
        visuals: const PanelVisuals(animationDuration: Duration(seconds: 1)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PanelScope(
            controller: controller,
            child: PanelArea(
              panelLayoutController: controller,
              panelIds: const [panelA, panelB],
            ),
          ),
        ),
      );

      // Show panel
      controller.getPanel(panelB)!.setVisible(visible: true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));

      final contentKey = ValueKey('panel_${panelB.value}_visible');
      final slideFinder = find.ancestor(
        of: find.byKey(contentKey),
        matching: find.byType(SlideTransition),
      );

      final slideTransition = tester.firstWidget<SlideTransition>(slideFinder);
      final offset = slideTransition.position.value;

      // CURRENT BEHAVIOR (BUG): Starts at -1 (Left).
      // EXPECTED BEHAVIOR: Start at +1 (Right) because it's anchored Left of Target, so it slides out from Target (Right).

      expect(offset.dx, greaterThan(0));
    });
  });
}
