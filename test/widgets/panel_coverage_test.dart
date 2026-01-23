import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/panel_layout.dart';
import 'package:panel_layout/src/widgets/animation/animated_panel.dart';

Finder findPanel(String id) => find.byWidgetPredicate(
  (w) => w is AnimatedPanel && w.config.id == PanelId(id),
);

void main() {
  group('Coverage Gaps', () {
    test('PanelLayoutController works when detached', () {
      final controller = PanelLayoutController();
      // These should not crash
      controller.toggleVisible(const PanelId('none'));
      controller.toggleCollapsed(const PanelId('none'));
      controller.setVisible(const PanelId('none'), true);
      controller.setCollapsed(const PanelId('none'), true);
    });

    testWidgets('PanelDataScope behavior', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PanelLayout(
            children: [
              InlinePanel(
                id: const PanelId('p1'),
                child: Builder(
                  builder: (context) {
                    final state = PanelDataScope.of(context);
                    expect(state.size, 0.0); // Content panel default
                    return Container();
                  },
                ),
              ),
            ],
          ),
        ),
      );
    });

    testWidgets('Delegate relative alignment paths', (tester) async {
      // Test Relative alignment math
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 800,
              height: 600,
              child: PanelLayout(
                
                children: [
                  InlinePanel(
                    id: const PanelId('base'),
                    width: 100,
                    height: 100,
                    child: Container(),
                  ),
                  // Anchor Right, Alignment Center (y=0.0)
                  OverlayPanel(
                    id: const PanelId('o1'),
                    anchor: PanelAnchor.right,
                    anchorTo: const PanelId('base'),
                    width: 50,
                    height: 50,
                    alignment: Alignment.centerRight,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    
                    child: Container(),
                  ),
                  // Anchor Bottom, Alignment Center (x=0.0)
                  OverlayPanel(
                    id: const PanelId('o2'),
                    anchor: PanelAnchor.bottom,
                    anchorTo: const PanelId('base'),
                    width: 50,
                    height: 50,
                    alignment: Alignment.bottomCenter,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    
                    child: Container(),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final o1Rect = tester.getRect(findPanel('o1'));
      final o2Rect = tester.getRect(findPanel('o2'));

      // o1 (Right of base, Centered vertically)
      // dx = base.right = 100.
      // dy = base.top + (base.height - child.height) * 0.5 = 0 + (600 - 50) * 0.5 = 275.
      expect(o1Rect.left, 100.0);
      expect(o1Rect.top, 275.0);

      // o2 (Bottom of base, Centered horizontally)
      // dy = base.bottom = 600. // Because it stretches vertically
      // dx = base.left + (base.width - child.width) * 0.5 = 0 + (100 - 50) * 0.5 = 25.
      expect(o2Rect.top, 600.0);
      expect(o2Rect.left, 25.0);
    });
  });
}
