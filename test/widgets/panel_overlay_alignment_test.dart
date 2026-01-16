import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/panel_layout.dart';
import 'package:panel_layout/src/widgets/animated_panel.dart';

Finder findPanel(String id) => find.byWidgetPredicate(
  (w) => w is AnimatedPanel && w.config.id == PanelId(id),
);

void main() {
  testWidgets('Overlay respects custom alignment', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 800,
            height: 600,
            child: PanelLayout(
              children: [
                OverlayPanel(
                  id: const PanelId('top-right'),
                  alignment: Alignment.topRight,
                  width: 100,
                  height: 100,
                  initialCollapsed: false,
                  child: Container(),
                ),
                OverlayPanel(
                  id: const PanelId('bottom-left'),
                  alignment: Alignment.bottomLeft,
                  width: 100,
                  height: 100,
                  initialCollapsed: false,
                  child: Container(),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final trRect = tester.getRect(findPanel('top-right'));
    final blRect = tester.getRect(findPanel('bottom-left'));

    // Top-Right: (800-100, 0)
    expect(trRect.left, 700.0);
    expect(trRect.top, 0.0);

    // Bottom-Left: (0, 600-100)
    expect(blRect.left, 0.0);
    expect(blRect.top, 500.0);
  });
}
