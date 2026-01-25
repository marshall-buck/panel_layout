import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/panel_layout.dart';

void main() {
  group('Easy Mode Panel Tests', () {
    testWidgets('InlinePanel renders title and icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PanelLayout(
            children: [
              InlinePanel(
                id: const PanelId('test'),
                width: 200,
                title: 'Test Title',
                icon: const Icon(Icons.close),
                child: const Text('Content'),
              ),
            ],
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
      // We expect 2 icons now: one in the header, one in the collapsed strip (fallback)
      expect(find.byIcon(Icons.close), findsNWidgets(2));
      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('InlinePanel icon toggles collapse', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PanelLayout(
            children: [
              InlinePanel(
                id: const PanelId('test'),
                width: 200,
                title: 'Test Title',
                icon: const Icon(Icons.chevron_left),
                child: const Text('Content'),
              ),
            ],
          ),
        ),
      );

      // Verify initial state
      final contentFinder = find.text('Content');
      PanelDataScope scope = tester.widget<PanelDataScope>(
        find
            .ancestor(of: contentFinder, matching: find.byType(PanelDataScope))
            .first,
      );
      expect(scope.state.collapsed, isFalse);

      // Tap the header icon (the one that is not ignored/invisible)
      await tester.tap(find.byIcon(Icons.chevron_left).hitTestable());
      await tester.pumpAndSettle();

      // Verify collapsed state
      scope = tester.widget<PanelDataScope>(
        find
            .ancestor(of: contentFinder, matching: find.byType(PanelDataScope))
            .first,
      );
      expect(scope.state.collapsed, isTrue);
    });

    testWidgets('PanelStyle styling is applied', (tester) async {
      const headerColor = Color(0xFFFF0000);
      const panelColor = Color(0xFF00FF00);

      await tester.pumpWidget(
        MaterialApp(
          home: PanelLayout(
            style: const PanelStyle(
              headerDecoration: BoxDecoration(color: headerColor),
              panelBoxDecoration: BoxDecoration(color: panelColor),
              headerPadding: 13.0,
            ),
            children: [
              InlinePanel(
                id: const PanelId('test'),
                width: 200,
                title: 'Themed Panel',
                child: const Text('Content'),
              ),
            ],
          ),
        ),
      );

      // Verify Header Height and Color
      // We look for a Container that has the header height constraint and decoration
      // Header height = iconSize (24 default) + padding (13) * 2 = 50.0
      final headerFinder = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.constraints?.maxHeight == 50.0) {
          final dec = widget.decoration;
          if (dec is BoxDecoration && dec.color == headerColor) {
            return true;
          }
        }
        return false;
      });
      expect(headerFinder, findsOneWidget);

      // Verify Panel Background
      // We look for a Container that has the panel decoration
      final panelFinder = find.byWidgetPredicate((widget) {
        if (widget is Container) {
          final dec = widget.decoration;
          if (dec is BoxDecoration && dec.color == panelColor) {
            return true;
          }
        }
        return false;
      });
      expect(panelFinder, findsOneWidget);
    });
  });
}
