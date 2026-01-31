import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_panels/flutter_panels.dart';
import 'package:flutter_panels/src/widgets/animation/animated_panel.dart';

Finder findPanel(String id) => find.byWidgetPredicate(
  (w) => w is AnimatedPanel && w.config.id == PanelId(id),
);

void main() {
  group('PanelAreaDelegate Extended', () {
    testWidgets('Top relative positioning', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 800,
              height: 600,
              child: PanelArea(
                children: [
                  InlinePanel(
                    id: const PanelId('base'),
                    height: 200,
                    child: Container(),
                  ),
                  OverlayPanel(
                    id: const PanelId('overlay'),
                    anchor: PanelAnchor.top,
                    anchorTo: const PanelId('base'),
                    height: 50,

                    child: Container(),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final baseRect = tester.getRect(findPanel('base'));
      final overlayRect = tester.getRect(findPanel('overlay'));

      expect(baseRect.top, 0.0);
      // Overlay (Anchor Top) should be ABOVE base.
      // dx = _alignAxis(base.left, base.width, 100, align.x);
      // dy = base.top - childHeight = 0 - 50 = -50.
      expect(overlayRect.top, -50.0);
    });

    testWidgets('Bottom relative positioning', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 800,
              height: 600,
              child: PanelArea(
                children: [
                  InlinePanel(
                    id: const PanelId('base'),
                    height: 200,
                    child: Container(),
                  ),
                  OverlayPanel(
                    id: const PanelId('overlay'),
                    anchor: PanelAnchor.bottom,
                    anchorTo: const PanelId('base'),
                    height: 50,

                    child: Container(),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final baseRect = tester.getRect(findPanel('base'));
      final overlayRect = tester.getRect(findPanel('overlay'));

      expect(baseRect.bottom, 200.0);
      expect(overlayRect.top, 200.0);
    });

    testWidgets('CrossAxisAlignment.start on Overlays', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 800,
              height: 600,
              child: PanelArea(
                children: [
                  InlinePanel(
                    id: const PanelId('base'),
                    width: 200,
                    child: Container(),
                  ),
                  OverlayPanel(
                    id: const PanelId('overlay'),
                    anchor: PanelAnchor.right,
                    anchorTo: const PanelId('base'),
                    width: 100,
                    height: 50,
                    crossAxisAlignment: CrossAxisAlignment.start,

                    child: Container(),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final overlayRect = tester.getRect(findPanel('overlay'));

      // Right anchor + Cross Start -> (200, centered)
      expect(overlayRect.left, 200.0);
      expect(overlayRect.top, 275.0); // (600 - 50) / 2
      expect(overlayRect.height, 50.0); // Not stretched
    });
  });
}
