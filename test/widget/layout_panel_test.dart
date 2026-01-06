import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/src/layout_panel.dart';
import 'package:panel_layout/src/panel_data.dart';
import 'package:panel_layout/src/panel_layout_controller.dart';
import 'package:panel_layout/src/panel_scope.dart';

void main() {
  group('LayoutPanel', () {
    late PanelLayoutController layoutController;
    const panelId = PanelId('test_panel');

    setUp(() {
      layoutController = PanelLayoutController();
    });

    tearDown(() {
      layoutController.dispose();
    });

    testWidgets('renders child when visible (FixedSizing)', (tester) async {
      final controller = layoutController.registerPanel(
        panelId,
        builder: (c, _) => const SizedBox(),
        sizing: const FixedSizing(100),
        mode: PanelMode.inline,
        anchor: PanelAnchor.left,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PanelScope(
            controller: layoutController,
            child: LayoutPanel(
              panelController: controller,
              child: const Text('Panel Content'),
            ),
          ),
        ),
      );

      expect(find.text('Panel Content'), findsOneWidget);
    });

    testWidgets('animates to size 0 when hidden (FixedSizing)', (tester) async {
      final controller = layoutController.registerPanel(
        panelId,
        builder: (c, _) => const SizedBox(),
        sizing: const FixedSizing(100),
        mode: PanelMode.inline,
        anchor: PanelAnchor.left,
        visuals: const PanelVisuals(
          animationDuration: Duration(milliseconds: 100),
          animationCurve: Curves.linear,
        ),
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PanelScope(
            controller: layoutController,
            child: Center(
              child: LayoutPanel(
                panelController: controller,
                child: const Text('Panel Content'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Panel Content'), findsOneWidget);
      // Ensure we found the right one.
      expect(find.byType(AnimatedContainer), findsOneWidget);

      expect(tester.getSize(find.byType(AnimatedContainer)).width, 100.0);

      // Hide
      controller.setVisible(visible: false);
      await tester.pump(); // Start animation
      await tester.pump(const Duration(milliseconds: 50)); // Halfway
      
      // Verify animating (size < 100)
      double currentWidth = tester.getSize(find.byType(AnimatedContainer)).width;
      
      // Linear: 100 -> 0. At 50%, should be 50.
      expect(currentWidth, closeTo(50.0, 1.0));

      await tester.pumpAndSettle(); // Finish animation
      
      // Should be 0 width
      expect(tester.getSize(find.byType(AnimatedContainer)).width, 0.0);
    });
    
    testWidgets('ContentSizing uses AnimatedSwitcher', (tester) async {
       final controller = layoutController.registerPanel(
        panelId,
        builder: (c, _) => const SizedBox(),
        sizing: const ContentSizing(),
        mode: PanelMode.inline,
        anchor: PanelAnchor.left,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PanelScope(
            controller: layoutController,
            child: LayoutPanel(
              panelController: controller,
              child: const Text('Panel Content'),
            ),
          ),
        ),
      );
      
      expect(find.byType(AnimatedSwitcher), findsOneWidget);
      expect(find.text('Panel Content'), findsOneWidget);
      
      controller.setVisible(visible: false);
      await tester.pumpAndSettle();
      
      // Text should be gone (replaced by SizedBox.shrink)
      expect(find.text('Panel Content'), findsNothing);
    });
  });
}
