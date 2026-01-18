import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/panel_layout.dart';
import 'package:panel_layout/src/widgets/animated_panel.dart';

Finder findPanel(String id) => find.byWidgetPredicate(
  (w) => w is AnimatedPanel && w.config.id == PanelId(id),
);

void main() {
  testWidgets('Overlay panel anchors to inline panel', (tester) async {
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
                  id: PanelId('base'),
                  width: 200,
                  child: Container(color: const Color(0xFF000000)),
                ),
                OverlayPanel(
                  id: PanelId('overlay'),
                  anchorTo: const PanelId('base'),
                  anchor: PanelAnchor.right,
                  width: 100,
                  initialCollapsed: false,
                  child: Container(color: const Color(0xFFFF0000)),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final baseRect = tester.getRect(findPanel('base'));
    final overlayRect = tester.getRect(findPanel('overlay'));

    expect(baseRect.left, 0.0);
    expect(baseRect.width, 200.0);
    expect(overlayRect.left, 200.0);
    expect(overlayRect.width, 100.0);
  });

  testWidgets('Overlay panel can anchor to another Overlay panel', (tester) async {
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
                  id: const PanelId('bg'),
                  flex: 1,
                  child: Container(),
                ),
                OverlayPanel(
                  id: const PanelId('overlay1'),
                  width: 100,
                  height: 100,
                  initialCollapsed: false,
                  // Center of screen roughly? Default alignment is centerLeft of screen if no anchorTo.
                  // Default delegate puts unanchored overlays at top left if alignment not specified?
                  // Let's specify alignment for clarity or rely on default.
                  // Delegate: unanchored -> Offset.zero & size -> alignment.inscribe -> topLeft.
                  // So overlay1 is at 0,0.
                  alignment: Alignment.topLeft,
                  child: Container(color: const Color(0xFF00FF00)),
                ),
                OverlayPanel(
                  id: const PanelId('overlay2'),
                  anchorTo: const PanelId('overlay1'),
                  anchor: PanelAnchor.right, // Should be to the right of overlay1
                  width: 50,
                  height: 50,
                  initialCollapsed: false,
                  child: Container(color: const Color(0xFF0000FF)),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final rect1 = tester.getRect(findPanel('overlay1'));
    final rect2 = tester.getRect(findPanel('overlay2'));

    expect(rect1.topLeft, Offset.zero);
    expect(rect1.width, 100.0);
    
    // overlay2 anchored right of overlay1
    expect(rect2.left, rect1.right);
    expect(rect2.width, 50.0);
  });
}
