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
                InlinePanel(id: PanelId('base'), width: 200, child: Container(color: const Color(0xFF000000))),
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
}
