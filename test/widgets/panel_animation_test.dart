import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/panel_layout.dart';

void main() {
  testWidgets('Panel with ContentSizing animates when toggling visibility', (
    tester,
  ) async {
    final controller = PanelLayoutController();
    const panelId1 = PanelId('panel_1');
    const panelId2 = PanelId('test_panel');

    // Panel 1: Fixed, Visible
    controller.registerPanel(
      panelId1,
      builder: (context, _) => Container(color: const Color(0xFF00FF00)),
      sizing: const FixedSizing(100),
      mode: PanelMode.inline,
      anchor: PanelAnchor.right,
      isVisible: true,
    );

    // Panel 2: Content, Invisible initially
    controller.registerPanel(
      panelId2,
      builder:
          (context, _) => Container(
            width: 200,
            height: 200,
            color: const Color(0xFFFF0000),
          ),
      sizing: const ContentSizing(),
      mode: PanelMode.inline,
      anchor: PanelAnchor.right,
      isVisible: false,
      visuals: const PanelVisuals(animationCurve: Curves.linear),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: PanelScope(
          controller: controller,
          child: Center(
            child: SizedBox(
              height: 400,
              width: 400,
              child: PanelArea(
                panelLayoutController: controller,
                panelIds: const [panelId1, panelId2],
              ),
            ),
          ),
        ),
      ),
    );

    // Initial state:
    // Panel 1 (Visible)
    // Panel 2 (Invisible)
    // List: [LayoutPanel(1), LayoutPanel(2)]

    // Find LayoutPanel for Panel 2
    final layoutPanels = find.byType(LayoutPanel);
    expect(layoutPanels, findsNWidgets(2));
    expect(find.byType(PanelResizeHandle), findsNothing);

    final panel2Finder = layoutPanels.at(1);

    // Initial size should be 0
    expect(tester.getSize(panel2Finder).width, 0.0);

    // Set visible = true
    controller.getPanel(panelId2)!.setVisible(visible: true);
    await tester.pump(); // Start animation (frame 0)

    // Check ResizeHandle exists
    expect(find.byType(PanelResizeHandle), findsOneWidget);

    // Find the new panel finder (it might have moved)
    final panel2FinderNew = find.byType(LayoutPanel).last;

    // Check size at 0ms.

    // If state is preserved, it should be 0 (start of animation).

    // If state is lost (recreated widget), it would jump to 200.

    final size0ms = tester.getSize(panel2FinderNew);

    // Pump 150ms (halfway of 300ms linear)

    await tester.pump(const Duration(milliseconds: 150));

    final Size sizeMid = tester.getSize(panel2FinderNew);

    // Pump until done

    await tester.pumpAndSettle();

    final Size sizeFinal = tester.getSize(panel2FinderNew);

    expect(sizeFinal.width, 200.0);

    // Regression check: Ensure animation starts from 0 and progresses.

    expect(size0ms.width, 0.0, reason: 'Should start at 0');

    expect(sizeMid.width, 100.0, reason: 'Should be 100 at 50%');
  });

  testWidgets(
    'FixedSizing panel content remains full size during closing animation',
    (tester) async {
      final controller = PanelLayoutController();
      const panelId = PanelId('fixed_panel');
      const fixedWidth = 200.0;

      controller.registerPanel(
        panelId,
        builder:
            (context, _) => Container(
              key: const ValueKey('content'),
              color: const Color(0xFF00FF00),
            ),
        sizing: const FixedSizing(fixedWidth),
        mode: PanelMode.inline,
        anchor: PanelAnchor.right,
        isVisible: true,
        visuals: const PanelVisuals(
          animationDuration: Duration(milliseconds: 1000),
          animationCurve: Curves.linear,
        ),
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PanelScope(
            controller: controller,
            child: Center(
              child: SizedBox(
                height: 400,
                width: 400,
                child: PanelArea(
                  panelLayoutController: controller,
                  panelIds: const [panelId],
                ),
              ),
            ),
          ),
        ),
      );

      // Initial state: Width 200
      final layoutPanelFinder = find.byType(LayoutPanel);
      final contentFinder = find.byKey(const ValueKey('content'));

      expect(tester.getSize(layoutPanelFinder).width, fixedWidth);
      expect(tester.getSize(contentFinder).width, fixedWidth);

      // Close the panel
      controller.getPanel(panelId)!.setVisible(visible: false);

      // Pump start of animation
      await tester.pump();

      // Pump 50% (500ms)
      await tester.pump(const Duration(milliseconds: 500));

      final panelSizeMid = tester.getSize(layoutPanelFinder);
      final contentSizeMid = tester.getSize(contentFinder);

      // The panel itself should be shrinking (approx 100)
      expect(
        panelSizeMid.width,
        closeTo(100.0, 1.0),
        reason: 'Panel should be halfway closed',
      );

      // THE BUG CHECK:
      // The content inside should still be full width (200), effectively clipped by the parent.
      expect(
        contentSizeMid.width,
        fixedWidth,
        reason:
            'Content should remain full width during close animation',
      );

      await tester.pumpAndSettle();
      expect(tester.getSize(layoutPanelFinder).width, 0.0);
    },
  );

  testWidgets(
    'ContentSizing panel content remains visible during closing animation',
    (tester) async {
      final controller = PanelLayoutController();
      const panelId = PanelId('content_panel');

      controller.registerPanel(
        panelId,
        builder:
            (context, _) => Container(
              key: const ValueKey('content'),
              width: 200, // Explicit width for content
              height: 200,
              color: const Color(0xFF00FF00),
            ),
        sizing: const ContentSizing(),
        mode: PanelMode.inline,
        anchor: PanelAnchor.right,
        isVisible: true,
        visuals: const PanelVisuals(
          animationDuration: Duration(milliseconds: 1000),
          animationCurve: Curves.linear,
        ),
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PanelScope(
            controller: controller,
            child: Center(
              child: SizedBox(
                height: 400,
                width: 400,
                child: PanelArea(
                  panelLayoutController: controller,
                  panelIds: const [panelId],
                ),
              ),
            ),
          ),
        ),
      );

      // Initial state: Width 200
      final layoutPanelFinder = find.byType(LayoutPanel);
      final contentFinder = find.byKey(const ValueKey('content'));

      expect(tester.getSize(layoutPanelFinder).width, 200.0);
      expect(tester.getSize(contentFinder).width, 200.0);

      // Close the panel
      controller.getPanel(panelId)!.setVisible(visible: false);

      // Pump start of animation
      await tester.pump();

      // Pump 50% (500ms)
      await tester.pump(const Duration(milliseconds: 500));

      final panelSizeMid = tester.getSize(layoutPanelFinder);

      // The panel itself should be shrinking (approx 100)
      expect(
        panelSizeMid.width,
        closeTo(100.0, 1.0),
        reason: 'Panel should be halfway closed',
      );

      // THE BUG CHECK:
      // The content inside should still be present in the tree and have its original size (or be clipped).
      expect(
        contentFinder,
        findsOneWidget,
        reason: 'Content widget should still be in the tree',
      );

      final contentSizeMid = tester.getSize(contentFinder);
      expect(
        contentSizeMid.width,
        200.0,
        reason: 'Content should remain full width during close animation',
      );

      await tester.pumpAndSettle();
      expect(tester.getSize(layoutPanelFinder).width, 0.0);
    },
  );
}
