import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/panel_layout.dart';
import 'package:panel_layout/src/widgets/animated_panel.dart';
import 'package:panel_layout/src/constants.dart';

Finder findPanel(String id) => find.byWidgetPredicate(
  (w) => w is AnimatedPanel && w.config.id == PanelId(id),
);

void main() {
  testWidgets('Panel animates to collapsed size', (tester) async {
    final controller = PanelLayoutController();
    const testIconSize = 4.0;
    const expectedCollapsedSize = testIconSize + kDefaultRailPadding; // 4 + 16 = 20

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 400,
            height: 100,
            child: PanelLayout(
              controller: controller,
              children: [
                InlinePanel(
                  id: const PanelId('p1'),
                  width: 100,
                  iconSize: testIconSize,
                  child: Container(),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(findPanel('p1')).width, 100.0);

    controller.toggleCollapsed(const PanelId('p1'));

    await tester.pumpAndSettle();
    expect(tester.getSize(findPanel('p1')).width, expectedCollapsedSize);
  });
}