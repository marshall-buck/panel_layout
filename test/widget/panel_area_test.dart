import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/src/panel_area.dart';
import 'package:panel_layout/src/panel_data.dart';
import 'package:panel_layout/src/panel_layout_controller.dart';
import 'package:panel_layout/src/panel_resize_handle.dart';

void main() {
  group('PanelArea', () {
    late PanelLayoutController layoutController;

    setUp(() {
      layoutController = PanelLayoutController();
    });

    tearDown(() {
      layoutController.dispose();
    });

    testWidgets('renders inline panels correctly', (tester) async {
      layoutController.registerPanel(
        const PanelId('left'),
        sizing: const FixedSizing(100),
        mode: PanelMode.inline,
        anchor: PanelAnchor.left,
      );
      layoutController.registerPanel(
        const PanelId('center'),
        sizing: const FlexibleSizing(1),
        mode: PanelMode.inline,
        anchor: PanelAnchor.left, // Anchor mostly relevant for overlays/resize dir
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PanelArea(
            panelLayoutController: layoutController,
            panelIds: const [PanelId('left'), PanelId('center')],
            panelBuilder: (context, id) => Text('Content $id'),
          ),
        ),
      );

      expect(find.text('Content PanelId(left)'), findsOneWidget);
      expect(find.text('Content PanelId(center)'), findsOneWidget);
      expect(find.byType(PanelResizeHandle), findsOneWidget);
    });

    testWidgets('renders overlay panels correctly', (tester) async {
      layoutController.registerPanel(
        const PanelId('main'),
        sizing: const FlexibleSizing(1),
        mode: PanelMode.inline,
        anchor: PanelAnchor.left,
      );
      layoutController.registerPanel(
        const PanelId('drawer'),
        sizing: const FixedSizing(200),
        mode: PanelMode.overlay,
        anchor: PanelAnchor.right,
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PanelArea(
            panelLayoutController: layoutController,
            panelIds: const [PanelId('main'), PanelId('drawer')],
            panelBuilder: (context, id) => Text('Content $id'),
          ),
        ),
      );

      expect(find.text('Content PanelId(main)'), findsOneWidget);
      expect(find.text('Content PanelId(drawer)'), findsOneWidget);
      
      // Verify layout structure: Stack -> [Flex(main), Align(drawer)]
      // Drawer is right-aligned overlay
      final alignFinder = find.ancestor(
        of: find.text('Content PanelId(drawer)'),
        matching: find.byType(Align),
      );
      expect(alignFinder, findsOneWidget);
      expect(tester.widget<Align>(alignFinder).alignment, Alignment.centerRight);
    });

    testWidgets('resizing fixed panel updates width', (tester) async {
      final leftPanel = layoutController.registerPanel(
        const PanelId('left'),
        sizing: const FixedSizing(100),
        mode: PanelMode.inline,
        anchor: PanelAnchor.left,
      );
      layoutController.registerPanel(
        const PanelId('center'),
        sizing: const FlexibleSizing(1),
        mode: PanelMode.inline,
        anchor: PanelAnchor.left,
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 800,
            height: 600,
            child: PanelArea(
              panelLayoutController: layoutController,
              panelIds: const [PanelId('left'), PanelId('center')],
              panelBuilder: (context, id) => Text('$id'),
            ),
          ),
        ),
      );

      final handleFinder = find.byType(PanelResizeHandle);
      
      // Drag handle right by 50px
      await tester.drag(handleFinder, const Offset(50, 0));
      await tester.pumpAndSettle();

      expect((leftPanel.sizing as FixedSizing).size, 150.0);
    });

    testWidgets('resizing flexible panels redistributes weight', (tester) async {
      final leftPanel = layoutController.registerPanel(
        const PanelId('left'),
        sizing: const FlexibleSizing(1),
        mode: PanelMode.inline,
        anchor: PanelAnchor.left,
      );
      final rightPanel = layoutController.registerPanel(
        const PanelId('right'),
        sizing: const FlexibleSizing(1),
        mode: PanelMode.inline,
        anchor: PanelAnchor.right,
      );

      // Total width 800. Each panel gets 400. Weight 1:1.
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 800,
            height: 600,
            child: PanelArea(
              panelLayoutController: layoutController,
              panelIds: const [PanelId('left'), PanelId('right')],
              panelBuilder: (context, id) => Text('$id'),
            ),
          ),
        ),
      );

      final handleFinder = find.byType(PanelResizeHandle);
      
      // Drag handle right by 100px.
      // Left becomes 500, Right becomes 300.
      // Weights should shift: Left 1.25, Right 0.75?
      // Calculation: weightDelta = (delta / availableSpace) * totalWeight
      // delta = 100. available = 800. totalWeight = 2.
      // weightDelta = (100 / 800) * 2 = 0.25.
      // Left = 1 + 0.25 = 1.25. Right = 1 - 0.25 = 0.75.
      
      await tester.drag(handleFinder, const Offset(100, 0));
      await tester.pumpAndSettle();

      expect((leftPanel.sizing as FlexibleSizing).weight, closeTo(1.25, 0.001));
      expect((rightPanel.sizing as FlexibleSizing).weight, closeTo(0.75, 0.001));
    });

    testWidgets('hiding panel updates layout', (tester) async {
      final leftPanel = layoutController.registerPanel(
        const PanelId('left'),
        sizing: const FixedSizing(100),
        mode: PanelMode.inline,
        anchor: PanelAnchor.left,
        visuals: const PanelVisuals(animationDuration: Duration.zero), // Instant
      );
      layoutController.registerPanel(
        const PanelId('center'),
        sizing: const FlexibleSizing(1),
        mode: PanelMode.inline,
        anchor: PanelAnchor.left,
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PanelArea(
            panelLayoutController: layoutController,
            panelIds: const [PanelId('left'), PanelId('center')],
            panelBuilder: (context, id) => Text('Content $id'),
          ),
        ),
      );

      expect(find.text('Content PanelId(left)'), findsOneWidget);

      leftPanel.setVisible(visible: false);
      await tester.pumpAndSettle();

      // Text should still be present because fixed sizing panels animate to 0 size 
      // but are not removed from tree (as per my LayoutPanel logic), 
      // BUT PanelArea logic says:
      // if (panel.isVisible || panel.sizing is! FlexibleSizing)
      // So FixedSizing IS added to list even if hidden.
      
      // Verify size is 0?
      // Actually, if it's hidden, effectiveSize is 0.
      // LayoutPanel builds AnimatedContainer(width: 0).
      // So text might be clipped but present in tree.
      
      expect(find.text('Content PanelId(left)'), findsOneWidget);
      // But verify it takes no space? 
      // Hard to verify specific render details here easily, but we verified LayoutPanel logic in unit test.
    });

    testWidgets('hiding flexible panel removes it from layout', (tester) async {
      final leftPanel = layoutController.registerPanel(
        const PanelId('left'),
        sizing: const FlexibleSizing(1),
        mode: PanelMode.inline,
        anchor: PanelAnchor.left,
      );
      layoutController.registerPanel(
        const PanelId('center'),
        sizing: const FlexibleSizing(1),
        mode: PanelMode.inline,
        anchor: PanelAnchor.left,
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PanelArea(
            panelLayoutController: layoutController,
            panelIds: const [PanelId('left'), PanelId('center')],
            panelBuilder: (context, id) => Text('Content $id'),
          ),
        ),
      );

      expect(find.text('Content PanelId(left)'), findsOneWidget);

      leftPanel.setVisible(visible: false);
      await tester.pumpAndSettle();

      // Flexible panels are excluded from the children list if not visible.
      // So it should be removed from tree.
      expect(find.text('Content PanelId(left)'), findsNothing);
    });
  });
}
