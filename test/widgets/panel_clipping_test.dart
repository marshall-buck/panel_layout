import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/panel_layout.dart';

void main() {
  testWidgets('InlinePanel applies ClipRect when clipContent is true', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: PanelLayout(
          children: [
            InlinePanel(
              id: const PanelId('panel1'),
              clipContent: true,
              child: const SizedBox(
                width: 100,
                height: 100,
                child: Text('Content'),
              ),
            ),
          ],
        ),
      ),
    );

    // Verify ClipRect exists
    expect(find.byType(ClipRect), findsOneWidget);
  });

  testWidgets('InlinePanel does not apply ClipRect when clipContent is false', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: PanelLayout(
          children: [
            InlinePanel(
              id: const PanelId('panel1'),
              clipContent: false,
              child: const SizedBox(
                width: 100,
                height: 100,
                child: Text('Content'),
              ),
            ),
          ],
        ),
      ),
    );

    // Verify ClipRect does not exist (BasePanel might use Clip.antiAlias on Container if decoration is present, but buildPanelLayout should not add ClipRect)
    // Actually, BasePanel uses Clip.antiAlias on the outer Container if decoration is present.
    // Our ClipRect is added inside buildPanelLayout specifically around content.
    expect(
      find.descendant(
        of: find.byType(InlinePanel),
        matching: find.byType(ClipRect),
      ),
      findsNothing,
    );
  });

  testWidgets('OverlayPanel applies ClipRect when clipContent is true', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: PanelLayout(
          children: [
            OverlayPanel(
              id: const PanelId('overlay1'),
              clipContent: true,
              child: const SizedBox(
                width: 100,
                height: 100,
                child: Text('Content'),
              ),
            ),
          ],
        ),
      ),
    );

    expect(find.byType(ClipRect), findsOneWidget);
  });
}
