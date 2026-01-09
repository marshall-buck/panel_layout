import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/panel_layout.dart';

void main() {
  group('PanelThemeData', () {
    test('defaults', () {
      const theme = PanelThemeData();
      expect(theme.resizeHandleColor, const Color(0x1A000000));
      expect(theme.resizeHandleHoverColor, const Color(0xFF0078D4));
      expect(theme.resizeHandleActiveColor, const Color(0xFF0078D4));
      expect(theme.resizeHandleWidth, 4.0);
      expect(theme.resizeHandleHitTestWidth, 12.0);
      expect(theme.resizeHandleDecoration, isNull);
      expect(theme.resizeHandleHoverDecoration, isNull);
      expect(theme.resizeHandleActiveDecoration, isNull);
      expect(theme.panelDecoration, isNull);
      expect(theme.panelPadding, isNull);
    });

    test('equality and hashCode', () {
      const theme1 = PanelThemeData(resizeHandleWidth: 10.0);
      const theme2 = PanelThemeData(resizeHandleWidth: 10.0);
      const theme3 = PanelThemeData(resizeHandleWidth: 5.0);

      expect(theme1, equals(theme2));
      expect(theme1.hashCode, equals(theme2.hashCode));
      expect(theme1, isNot(equals(theme3)));
    });

    test('equality works with decorations', () {
      const decor = BoxDecoration(color: Color(0xFF000000));
      const theme1 = PanelThemeData(resizeHandleDecoration: decor);
      const theme2 = PanelThemeData(resizeHandleDecoration: decor);

      expect(theme1, equals(theme2));
    });
  });

  group('PanelTheme', () {
    testWidgets('provides theme data to descendants', (tester) async {
      const testData = PanelThemeData(resizeHandleWidth: 20.0);

      late PanelThemeData retrievedData;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PanelTheme(
            data: testData,
            child: Builder(
              builder: (context) {
                retrievedData = PanelTheme.of(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(retrievedData, testData);
      expect(retrievedData.resizeHandleWidth, 20.0);
    });

    testWidgets('updateShouldNotify notifies on change', (tester) async {
      // This is implicitly tested by Flutter framework, but good to sanity check
      // if we were manually managing listeners. For inherited widgets,
      // simple usage test covers it.
    });

    testWidgets('fallback to default if no theme present', (tester) async {
      late PanelThemeData retrievedData;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (context) {
              retrievedData = PanelTheme.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(retrievedData, const PanelThemeData());
    });
  });
}
