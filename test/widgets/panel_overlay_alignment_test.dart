import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/panel_layout.dart';
import 'package:panel_layout/src/widgets/animated_panel.dart';

class TestOverlay extends BasePanel {
  TestOverlay({
    super.key,
    required String id,
    super.alignment,
    super.anchor = PanelAnchor.left,
  }) : super(
    id: PanelId(id),
    mode: PanelMode.overlay,
    width: 100,
    height: 100,
    child: Container(),
  );
}

Finder findPanel(String id) => find.byWidgetPredicate((w) => w is AnimatedPanel && w.config.id == PanelId(id));

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
                TestOverlay(id: 'top-right', alignment: Alignment.topRight),
                TestOverlay(id: 'bottom-left', alignment: Alignment.bottomLeft),
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
