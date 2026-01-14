import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/panel_layout.dart';
import 'package:panel_layout/src/widgets/animated_panel.dart';

class InlinePanel extends BasePanel {
  InlinePanel({super.key, required String id})
    : super(
        id: PanelId(id),
        width: 200,
        mode: PanelMode.inline,
        child: Container(color: const Color(0xFF000000)),
      );
}

class OverlayPanel extends BasePanel {
  OverlayPanel({
    super.key,
    required String id,
    required PanelId anchorTo,
    super.anchor = PanelAnchor.right,
  }) : super(
         id: PanelId(id),
         mode: PanelMode.overlay,
         anchorTo: anchorTo,
         width: 100,
         child: Container(color: const Color(0xFFFF0000)),
       );
}

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
                InlinePanel(id: 'base'),
                OverlayPanel(id: 'overlay', anchorTo: const PanelId('base')),
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
