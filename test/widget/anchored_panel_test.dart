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
        sizing: const FlexibleSizing(1.0),
        mode: PanelMode.inline,
        anchor: PanelAnchor.left,
      );

      // Register Panel B (Anchored to A, Left)
      controller.registerPanel(
        panelB,
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
              ], // Order in list doesn't matter for anchored
              panelBuilder: (context, id) => Text(id.value),
            ),
          ),
        ),
      );

      // Verify order in the Row/Column
      // We expect: [Panel B] [Panel A]
      final flexFinder = find.byType(Flex);
      tester.widget<Flex>(flexFinder.first);

      // We can't easily inspect children order directly from Flex widget without keys or deeper inspection.
      // But we can check the Finder order.
      final textFinder = find.byType(Text);
      expect(textFinder, findsNWidgets(2));

      final firstText = tester.widget<Text>(textFinder.at(0));
      final secondText = tester.widget<Text>(textFinder.at(1));

      expect(firstText.data, 'panelB');
      expect(secondText.data, 'panelA');
    });

    testWidgets('Panel B anchored RIGHT of Panel A should appear AFTER A', (
      tester,
    ) async {
      final controller = PanelLayoutController();

      controller.registerPanel(
        panelA,
        sizing: const FlexibleSizing(1.0),
        mode: PanelMode.inline,
        anchor: PanelAnchor.left,
      );

      controller.registerPanel(
        panelB,
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
              panelBuilder: (context, id) => Text(id.value),
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
      'Overlay Panel anchored to another uses CompositedTransformFollower',
      (tester) async {
        final controller = PanelLayoutController();

        controller.registerPanel(
          panelA,
          sizing: const FlexibleSizing(1.0),
          mode: PanelMode.inline,
          anchor: PanelAnchor.left,
        );

        controller.registerPanel(
          panelB,
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
                panelBuilder: (context, id) => Text(id.value),
              ),
            ),
          ),
        );

        // Verify that CompositedTransformFollower exists
        expect(find.byType(CompositedTransformFollower), findsOneWidget);

        // Verify that CompositedTransformTarget exists (for Panel A)
        expect(find.byType(CompositedTransformTarget), findsWidgets);
      },
    );

    testWidgets('Overlay Panel without anchor uses Align (Global)', (
      tester,
    ) async {
      final controller = PanelLayoutController();

      controller.registerPanel(
        panelA,
        sizing: const FlexibleSizing(1.0),
        mode: PanelMode.inline,
        anchor: PanelAnchor.left,
      );

      controller.registerPanel(
        panelB,
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
              panelBuilder: (context, id) => Text(id.value),
            ),
          ),
        ),
      );

      // Should verify we are using Align logic, not Follower logic for B
      // Note: Panel A is wrapped in Target, so Target exists.
      // But B should be in a Stack -> Align -> Flex.
      // We can check that we have an Align with Alignment.centerRight containing Panel B

      final alignFinder = find.ancestor(
        of: find.text('panelB'),
        matching: find.byType(Align),
      );

      expect(alignFinder, findsOneWidget);
      final align = tester.widget<Align>(alignFinder.first);
      expect(align.alignment, Alignment.centerRight);
    });
  });
}
