import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/panel_layout.dart';

void main() {
  const panelA = PanelId('panelA');
  const panelB = PanelId('panelB');

  group('Anchored Inline Panels', () {
    testWidgets('Panel B anchored LEFT of Panel A should appear BEFORE A', (
      tester,
    ) async {
      final controller = PanelLayoutController();

      // Register Panel A (Standard)
      controller.registerPanel(
        panelA,
        builder: (context, _) => Text(panelA.value),
        sizing: const FlexibleSizing(1.0),
        mode: PanelMode.inline,
        anchor: PanelAnchor.left,
      );

      // Register Panel B (Anchored to A, Left)
      controller.registerPanel(
        panelB,
        builder: (context, _) => Text(panelB.value),
        sizing: const FixedSizing(100),
        mode: PanelMode.inline,
        anchor: PanelAnchor.left,
        anchorPanel: panelA,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PanelScope(
            controller: controller,
            child: PanelArea(
              panelLayoutController: controller,
              panelIds: const [
                panelA,
                panelB,
              ], 
            ),
          ),
        ),
      );

      // Flex check is implementation detail (MultiChildLayout used now)
      // But verify text order in Finder might still work if children are painted in order?
      // CustomMultiChildLayout paints children in order of layout/paint.
      // We rely on layout positions.
      
      // Verify order in the Row/Column
      // We expect: [Panel B] [Panel A]
      // Since PanelArea uses CustomMultiChildLayout, tree order might follow panelIds (A, B).
      // But VISUALLY, B should be to the Left of A.
      
      final rectA = tester.getRect(find.text('panelA'));
      final rectB = tester.getRect(find.text('panelB'));
      
      // B (Left anchor) should be to the Left of A
      // Note: A resize handle (width ~12) is inserted between them.
      expect(rectB.right, lessThanOrEqualTo(rectA.left), reason: 'Panel B should be to the left of Panel A');
      expect(rectB.left, lessThan(rectA.left));
    });

    testWidgets('Panel B anchored RIGHT of Panel A should appear AFTER A', (
      tester,
    ) async {
      final controller = PanelLayoutController();

      controller.registerPanel(
        panelA,
        builder: (context, _) => Text(panelA.value),
        sizing: const FlexibleSizing(1.0),
        mode: PanelMode.inline,
        anchor: PanelAnchor.left,
      );

      controller.registerPanel(
        panelB,
        builder: (context, _) => Text(panelB.value),
        sizing: const FixedSizing(100),
        mode: PanelMode.inline,
        anchor: PanelAnchor.right,
        anchorPanel: panelA,
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

      final textFinder = find.byType(Text);
      expect(tester.widget<Text>(textFinder.at(0)).data, 'panelA');
      expect(tester.widget<Text>(textFinder.at(1)).data, 'panelB');
    });
  });

  group('Anchored Overlay Panels', () {
    testWidgets(
      'Overlay Panel anchored to another is positioned correctly (Custom Layout)',
      (tester) async {
        final controller = PanelLayoutController();

        controller.registerPanel(
          panelA,
          builder: (context, _) => Text(panelA.value),
          sizing: const FlexibleSizing(1.0),
          mode: PanelMode.inline,
          anchor: PanelAnchor.left,
        );

        controller.registerPanel(
          panelB,
          builder: (context, _) => Text(panelB.value),
          sizing: const FixedSizing(200),
          mode: PanelMode.overlay,
          anchor: PanelAnchor.right, // Should attach to Right of A
          anchorPanel: panelA,
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

        // Verify Positions
        final rectA = tester.getRect(find.text('panelA'));
        final rectB = tester.getRect(find.text('panelB'));
        
        // Panel B (Right anchor) should be to the right of Panel A
        expect(rectB.left, equals(rectA.right));
      },
    );

    testWidgets('Overlay Panel without anchor uses Global Positioning', (
      tester,
    ) async {
      final controller = PanelLayoutController();

      controller.registerPanel(
        panelA,
        builder: (context, _) => Text(panelA.value),
        sizing: const FlexibleSizing(1.0),
        mode: PanelMode.inline,
        anchor: PanelAnchor.left,
      );

      controller.registerPanel(
        panelB,
        builder: (context, _) => Text(panelB.value),
        sizing: const FixedSizing(200),
        mode: PanelMode.overlay,
        anchor: PanelAnchor.right,
        // No anchorPanel
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

      // Verify Global Positioning (Right Aligned)
      final rectB = tester.getRect(find.text('panelB'));
      final screenRect = tester.getRect(find.byType(MaterialApp));
      
      expect(rectB.right, equals(screenRect.right));
    });
  });
}