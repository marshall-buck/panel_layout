import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/panel_layout.dart';
import 'package:panel_layout/src/widgets/animated_panel.dart';

Finder findPanel(String id) => find.byWidgetPredicate(
  (w) => w is AnimatedPanel && w.config.id == PanelId(id),
);

void main() {
  testWidgets('Content sizing panel expands to fit child', (tester) async {
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
                  id: const PanelId('c1'),
                  child: const SizedBox(width: 123, height: 100),
                ),
                InlinePanel(
                  id: const PanelId('fill'),
                  flex: 1,
                  child: Container(),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(findPanel('c1')).width, 123.0);
  });
}
