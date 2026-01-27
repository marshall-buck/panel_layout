import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/panel_layout.dart';
import '../utils/test_content_panel.dart';

void main() {
  double getPanelSize(WidgetTester tester, PanelId id, Axis axis) {
     final layoutId = tester.widget<LayoutId>(
       find.descendant(of: find.byType(CustomMultiChildLayout), matching: find.byWidgetPredicate((w) => w is LayoutId && w.id == id)).first
     );
     final context = tester.element(find.byWidget(layoutId.child));
     final size = context.size!;
     return axis == Axis.horizontal ? size.width : size.height;
  }

  group('Directional Stability Tests', () {
    
    testWidgets('Anchor Right: Right neighbor (Next) stays stable', (tester) async {
      final controller = PanelLayoutController();
      // [Flex A] [Fixed B (Anchor Right)] [Flex C]
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PanelLayout(
              controller: controller,
              children: [
                TestContentPanel(id: PanelId('A'), child: Container()),
                InlinePanel(id: PanelId('B'), width: 100, anchor: PanelAnchor.right, child: Container()),
                TestContentPanel(id: PanelId('C'), child: Container()),
              ],
            ),
          ),
        ),
      );

      final initialC = getPanelSize(tester, PanelId('C'), Axis.horizontal);

      // Collapse B
      controller.setCollapsed(PanelId('B'), true);
      await tester.pump(); 
      await tester.pump(const Duration(milliseconds: 50)); 

      final midC = getPanelSize(tester, PanelId('C'), Axis.horizontal);
      
      expect(midC, closeTo(initialC, 0.01), reason: 'Neighbor C (Right) should not move/resize when B (Anchor Right) collapses');
    });

    testWidgets('Anchor Left: Left neighbor (Prev) stays stable', (tester) async {
      final controller = PanelLayoutController();
      // [Flex A] [Fixed B (Anchor Left)] [Flex C]
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PanelLayout(
              controller: controller,
              children: [
                TestContentPanel(id: PanelId('A'), child: Container()),
                InlinePanel(id: PanelId('B'), width: 100, anchor: PanelAnchor.left, child: Container()),
                TestContentPanel(id: PanelId('C'), child: Container()),
              ],
            ),
          ),
        ),
      );

      final initialA = getPanelSize(tester, PanelId('A'), Axis.horizontal);
      
      // Collapse B
      controller.setCollapsed(PanelId('B'), true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final midA = getPanelSize(tester, PanelId('A'), Axis.horizontal);
      
      expect(midA, closeTo(initialA, 0.01), reason: 'Neighbor A (Left) should not move/resize when B (Anchor Left) collapses');
    });

    testWidgets('Anchor Bottom: Bottom neighbor (Next) stays stable', (tester) async {
      final controller = PanelLayoutController();
      // [Flex A]
      // [Fixed B (Anchor Bottom)]
      // [Flex C]
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PanelLayout(
              controller: controller,
              children: [
                TestContentPanel(id: PanelId('A'), child: Container()),
                InlinePanel(id: PanelId('B'), height: 100, anchor: PanelAnchor.bottom, child: Container()),
                TestContentPanel(id: PanelId('C'), child: Container()),
              ],
            ),
          ),
        ),
      );

      final initialC = getPanelSize(tester, PanelId('C'), Axis.vertical);
      
      // Collapse B
      controller.setCollapsed(PanelId('B'), true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final midC = getPanelSize(tester, PanelId('C'), Axis.vertical);
      
      expect(midC, closeTo(initialC, 0.01), reason: 'Neighbor C (Bottom) should not move/resize when B (Anchor Bottom) collapses');
    });

    testWidgets('Anchor Top: Top neighbor (Prev) stays stable', (tester) async {
      final controller = PanelLayoutController();
      // [Flex A]
      // [Fixed B (Anchor Top)]
      // [Flex C]
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PanelLayout(
              controller: controller,
              children: [
                TestContentPanel(id: PanelId('A'), child: Container()),
                InlinePanel(id: PanelId('B'), height: 100, anchor: PanelAnchor.top, child: Container()),
                TestContentPanel(id: PanelId('C'), child: Container()),
              ],
            ),
          ),
        ),
      );

      final initialA = getPanelSize(tester, PanelId('A'), Axis.vertical);
      
      // Collapse B
      controller.setCollapsed(PanelId('B'), true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final midA = getPanelSize(tester, PanelId('A'), Axis.vertical);
      
      expect(midA, closeTo(initialA, 0.01), reason: 'Neighbor A (Top) should not move/resize when B (Anchor Top) collapses');
    });
  });
}