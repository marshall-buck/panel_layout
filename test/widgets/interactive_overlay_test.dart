import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/panel_layout.dart';

void main() {
  group('Interactive Overlay Panels', () {
    testWidgets('Button triggers panel slide in from Top-Center', (
      tester,
    ) async {
      final layoutController = PanelLayoutController();
      const mainId = PanelId('main');
      const overlayId = PanelId('overlay');

      layoutController.registerPanel(
        mainId,
        builder: (context, _) => Center(
          child: ElevatedButton(
            onPressed: () {
              layoutController
                  .getPanelOrThrow(overlayId)
                  .setVisible(visible: true);
            },
            child: const Text('Open Overlay'),
          ),
        ),
        sizing: const FlexibleSizing(1),
        mode: PanelMode.inline,
        anchor: PanelAnchor.left,
      );

      layoutController.registerPanel(
        overlayId,
        builder: (context, _) => Container(
          key: const Key('overlay_content'),
          width: 200,
          height: 100,
          color: Colors.red,
          child: const Text('Overlay Content'),
        ),
        sizing: const FixedSizing(100),
        mode: PanelMode.overlay,
        anchor: PanelAnchor.top,
        alignment: Alignment.topCenter,
        crossAxisAlignment: CrossAxisAlignment.center, // Center horizontally
        isVisible: false, // Start hidden
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PanelScope(
            controller: layoutController,
            child: PanelArea(
              panelLayoutController: layoutController,
              panelIds: const [mainId, overlayId],
            ),
          ),
        ),
      );

      // Verify overlay is hidden initially
      expect(find.text('Overlay Content'), findsNothing);

      // Tap the button
      await tester.tap(find.text('Open Overlay'));
      await tester.pump(); // Start animation/state change

      // Verify overlay is now in the tree
      expect(find.text('Overlay Content'), findsOneWidget);

      // Verify positioning (Top Center)
      // The overlay should be wrapped in an Align widget with Alignment.topCenter
      final alignFinder = find.ancestor(
        of: find.text('Overlay Content'),
        matching: find.byType(Align),
      );
      expect(alignFinder, findsOneWidget);
      final align = tester.widget<Align>(alignFinder.first);
      expect(align.alignment, Alignment.topCenter);

      // Verify sizing (not full width due to CrossAxisAlignment.center)
      final contentFinder = find.byKey(const Key('overlay_content'));
      final size = tester.getSize(contentFinder);
      expect(size.width, 200);
      expect(size.height, 100);

      await tester.pumpAndSettle(); // Finish animations
    });

    testWidgets('Overlay panel can be dismissed (visibility toggled off)', (
      tester,
    ) async {
      final layoutController = PanelLayoutController();
      const overlayId = PanelId('overlay');

      layoutController.registerPanel(
        overlayId,
        builder: (context, _) => const Text('Overlay Content'),
        sizing: const FixedSizing(100),
        mode: PanelMode.overlay,
        anchor: PanelAnchor.bottom,
        isVisible: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PanelScope(
            controller: layoutController,
            child: PanelArea(
              panelLayoutController: layoutController,
              panelIds: const [overlayId],
            ),
          ),
        ),
      );

      expect(find.text('Overlay Content'), findsOneWidget);

      // Hide it
      layoutController.getPanelOrThrow(overlayId).setVisible(visible: false);
      await tester.pumpAndSettle();

      expect(find.text('Overlay Content'), findsNothing);
    });

    testWidgets('Button triggers panel slide in from Bottom-Center', (
      tester,
    ) async {
      final layoutController = PanelLayoutController();
      const mainId = PanelId('main');
      const bottomId = PanelId('bottom');

      layoutController.registerPanel(
        mainId,
        builder: (context, _) => const SizedBox(),
        sizing: const FlexibleSizing(1),
        mode: PanelMode.inline,
        anchor: PanelAnchor.left,
      );

      layoutController.registerPanel(
        bottomId,
        builder: (context, _) => Container(
          key: const Key('bottom_content'),
          height: 100,
          color: Colors.blue,
          child: const Text('Bottom Content'),
        ),
        sizing: const FixedSizing(100),
        mode: PanelMode.overlay,
        anchor: PanelAnchor.bottom,
        alignment: Alignment.bottomCenter,
        isVisible: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PanelScope(
            controller: layoutController,
            child: PanelArea(
              panelLayoutController: layoutController,
              panelIds: const [mainId, bottomId],
            ),
          ),
        ),
      );

      // Show it
      layoutController.getPanelOrThrow(bottomId).setVisible(visible: true);
      await tester.pump(); // Start animation

      expect(find.text('Bottom Content'), findsOneWidget);

      // Verify alignment
      final alignFinder = find.ancestor(
        of: find.text('Bottom Content'),
        matching: find.byType(Align),
      );
      expect(alignFinder, findsOneWidget);
      expect(
        tester.widget<Align>(alignFinder).alignment,
        Alignment.bottomCenter,
      );

      await tester.pumpAndSettle();
    });

    testWidgets('Button triggers panel slide in from Left', (tester) async {
      final layoutController = PanelLayoutController();
      const mainId = PanelId('main');
      const leftId = PanelId('left');

      layoutController.registerPanel(
        mainId,
        builder: (context, _) => const SizedBox(),
        sizing: const FlexibleSizing(1),
        mode: PanelMode.inline,
        anchor: PanelAnchor.left,
      );

      layoutController.registerPanel(
        leftId,
        builder: (context, _) => Container(
          width: 200,
          color: Colors.green,
          child: const Text('Left Content'),
        ),
        sizing: const FixedSizing(200),
        mode: PanelMode.overlay,
        anchor: PanelAnchor.left,
        alignment: Alignment.centerLeft,
        isVisible: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PanelScope(
            controller: layoutController,
            child: PanelArea(
              panelLayoutController: layoutController,
              panelIds: const [mainId, leftId],
            ),
          ),
        ),
      );

      // Show it
      layoutController.getPanelOrThrow(leftId).setVisible(visible: true);
      await tester.pump();

      expect(find.text('Left Content'), findsOneWidget);

      // Verify alignment
      final alignFinder = find.ancestor(
        of: find.text('Left Content'),
        matching: find.byType(Align),
      );
      expect(alignFinder, findsOneWidget);
      expect(tester.widget<Align>(alignFinder).alignment, Alignment.centerLeft);

      await tester.pumpAndSettle();
    });
  });
}
