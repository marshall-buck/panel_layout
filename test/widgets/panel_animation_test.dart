import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/panel_layout.dart';
import 'package:panel_layout/src/widgets/animated_panel.dart';

class TestFixedPanel extends BasePanel {
  TestFixedPanel({
    super.key,
    required String id,
    required double width,
    super.mode,
    super.anchor,
    super.anchorTo,
  }) : super(id: PanelId(id), width: width, child: const SizedBox.shrink());
}

void main() {
  testWidgets('Panel animates size when hidden', (tester) async {
    final controller = PanelLayoutController();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 400,
            height: 100,
            child: PanelLayout(
              controller: controller,
              children: [TestFixedPanel(id: 'p1', width: 100)],
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(TestFixedPanel)).width, 100.0);

    controller.setVisible(const PanelId('p1'), false);

    // Start animation
    await tester.pump();

    // Halfway (Default is 250ms)
    await tester.pump(const Duration(milliseconds: 125));
    final intermediateWidth = tester.getSize(find.byType(AnimatedPanel)).width;
    expect(intermediateWidth, closeTo(50.0, 1.0));

    // End
    await tester.pump(const Duration(milliseconds: 125));
    expect(tester.getSize(find.byType(AnimatedPanel)).width, 0.0);
  });

  testWidgets(
    'Anchored overlay panel animates out instead of disappearing instantly',
    (tester) async {
      final controller = PanelLayoutController();
      const duration = Duration(milliseconds: 100);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PanelLayout(
              controller: controller,
              children: [
                TestFixedPanel(id: 'main', width: 300),
                TestFixedPanel(
                  id: 'overlay',
                  mode: PanelMode.overlay,
                  anchor: PanelAnchor.right,
                  anchorTo: const PanelId('main'),
                  width: 100,
                ),
              ],
            ),
          ),
        ),
      );

      // Initial state: Overlay is visible
      expect(find.byType(TestFixedPanel), findsNWidgets(2));
      final Size initialSize = tester.getSize(find.byType(AnimatedPanel).last);
      expect(initialSize.width, 100.0);

      // Trigger close
      controller.setVisible(const PanelId('overlay'), false);
      await tester.pump(); // Start animation

      // Halfway through animation
      await tester.pump(duration ~/ 2);

      // Measure the ClipRect to see the effective animated size
      final Size midSize = tester.getSize(
        find.descendant(
          of: find.byType(AnimatedPanel).last,
          matching: find.byType(ClipRect),
        ),
      );

      expect(
        midSize.width,
        greaterThan(0.0),
        reason: 'Panel width should be > 0 during animation',
      );
      expect(
        midSize.width,
        lessThan(100.0),
        reason: 'Panel width should be < 100 during animation',
      );

      // Finish animation
      await tester.pumpAndSettle();

      // It should be gone (SizedBox.shrink does not build child)
      // The AnimatedPanel itself returns SizedBox.shrink, which has size 0x0
      final Size finalSize = tester.getSize(find.byType(AnimatedPanel).last);
      expect(finalSize.width, 0.0);
    },
  );
}
