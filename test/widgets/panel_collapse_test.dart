import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_panels/flutter_panels.dart';
import 'package:flutter_panels/src/widgets/animation/animated_panel.dart';
import 'package:flutter_panels/src/core/constants.dart';

Finder findPanel(String id) => find.byWidgetPredicate(
  (w) => w is AnimatedPanel && w.config.id == PanelId(id),
);

void main() {
  testWidgets('Panel animates to collapsed size', (tester) async {
    final controller = PanelAreaController();
    const testIconSize = 4.0;
    const expectedCollapsedSize =
        testIconSize + kDefaultRailPadding; // 4 + 16 = 20

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 400,
            height: 100,
            child: PanelArea(
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
