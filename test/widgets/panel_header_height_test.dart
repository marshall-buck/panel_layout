import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/panel_layout.dart';

void main() {
  group('Panel Header Height Logic', () {
    testWidgets(
      'calculates height dynamically from iconSize and config padding',
      (tester) async {
        const testIconSize = 24.0;
        const testPadding = 10.0;
        const expectedHeight = testIconSize + (testPadding * 2); // 44.0
        const panelId = PanelId('p1');

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: PanelLayout(
              style: const PanelStyle(
                iconSize: testIconSize,
                headerPadding: testPadding,
              ),
              children: [
                InlinePanel(
                  id: panelId,
                  width: 200,
                  title: 'Title',
                  icon: const SizedBox(),
                  child: Container(),
                ),
              ],
            ),
          ),
        );

        final headerFinder = find.byKey(Key('panel_header_${panelId.value}'));
        expect(tester.getSize(headerFinder).height, expectedHeight);
      },
    );

    testWidgets('panel headerPadding overrides config headerPadding', (
      tester,
    ) async {
      const testIconSize = 24.0;
      const configPadding = 5.0;
      const panelPadding = 15.0;
      const expectedHeight = testIconSize + (panelPadding * 2); // 54.0
      const panelId = PanelId('p1');

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PanelLayout(
            style: const PanelStyle(
              iconSize: testIconSize,
              headerPadding: configPadding,
            ),
            children: [
              InlinePanel(
                id: panelId,
                width: 200,
                headerPadding: panelPadding,
                title: 'Title',
                icon: const SizedBox(),
                child: Container(),
              ),
            ],
          ),
        ),
      );

      final headerFinder = find.byKey(Key('panel_header_${panelId.value}'));
      expect(tester.getSize(headerFinder).height, expectedHeight);
    });

    testWidgets('panel headerHeight overrides everything', (tester) async {
      const explicitHeight = 48.0;
      const panelId = PanelId('p1');

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PanelLayout(
            style: const PanelStyle(iconSize: 24, headerPadding: 8),
            children: [
              InlinePanel(
                id: panelId,
                width: 200,
                headerHeight: explicitHeight,
                title: 'Title',
                icon: const SizedBox(),
                child: Container(),
              ),
            ],
          ),
        ),
      );

      final headerFinder = find.byKey(Key('panel_header_${panelId.value}'));
      expect(tester.getSize(headerFinder).height, explicitHeight);
    });
  });
}
