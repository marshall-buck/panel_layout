import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_panels/flutter_panels.dart';
import 'package:flutter_panels/src/widgets/animation/animated_panel.dart';
import '../utils/test_content_panel.dart';

Finder findPanel(String id) => find.byWidgetPredicate(
  (w) => w is AnimatedPanel && w.config.id == PanelId(id),
);

void main() {
  testWidgets('PanelArea renders fixed panels with correct width', (
    tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            height: 100,
            width: 800,
            child: PanelArea(
              children: [
                InlinePanel(
                  id: const PanelId('p1'),
                  width: 100,
                  child: Container(color: const Color(0xFFFF0000)),
                ),
                InlinePanel(
                  id: const PanelId('p2'),
                  width: 200,
                  child: Container(color: const Color(0xFFFF0000)),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(findPanel('p1')).width, 100.0);
    expect(tester.getSize(findPanel('p2')).width, 200.0);
  });

  testWidgets('PanelArea distributes flex space accounting for handle', (
    tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 400,
            height: 100,
            child: PanelArea(
              children: [
                TestContentPanel(
                  id: const PanelId('f1'),
                  layoutWeightOverride: 1,
                  child: Container(color: const Color(0xFF00FF00)),
                ),
                TestContentPanel(
                  id: const PanelId('f2'),
                  layoutWeightOverride: 3,
                  child: Container(color: const Color(0xFF00FF00)),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(findPanel('f1')).width, 100.0);
    expect(tester.getSize(findPanel('f2')).width, 300.0);
  });

  testWidgets('PanelArea mixes Fixed and Flex panels', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 500,
            height: 100,
            child: PanelArea(
              children: [
                InlinePanel(
                  id: const PanelId('fixed'),
                  width: 100,
                  child: Container(color: const Color(0xFFFF0000)),
                ),
                TestContentPanel(
                  id: const PanelId('flex'),
                  layoutWeightOverride: 1,
                  child: Container(color: const Color(0xFF00FF00)),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(findPanel('fixed')).width, 100.0);
    expect(tester.getSize(findPanel('flex')).width, 392.0);
  });
}
