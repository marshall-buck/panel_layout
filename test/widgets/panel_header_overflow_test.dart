import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_panels/flutter_panels.dart';

void main() {
  testWidgets('Header row handles extreme narrow constraints without overflow', (
    WidgetTester tester,
  ) async {
    // We create a panel and force its header to be extremely narrow (e.g., 10 pixels).
    // The icon is usually 24px, so this will trigger the clipping logic and hide the title.

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 10, // Extremely narrow
            height: 400,
            child: PanelArea(
              children: [
                InlinePanel(
                  id: const PanelId('narrow_panel'),
                  title: 'This is a long title that should be hidden',
                  icon: const Icon(Icons.chevron_left),
                  width: 10, // Match the parent
                  child: const SizedBox.expand(),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // If an overflow occurred, Flutter would have thrown an assertion during the pump.
    // We check that the Text widget is NOT found or is not visible because it should be hidden by our logic.
    // In our implementation, we return an Align with a ClipRect(toggleButton) when width < requiredFixedSpace.

    expect(
      find.text('This is a long title that should be hidden'),
      findsNothing,
    );

    // Check that we find the ClipRect which contains the toggle button
    expect(find.byType(ClipRect), findsWidgets);

    // No overflow errors should be in the logs.
    // tester.takeException() returns the last exception caught by the tester.
    expect(tester.takeException(), isNull);
  });

  testWidgets('Header row shows title when enough space is available', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: PanelArea(
          children: [
            InlinePanel(
              id: const PanelId('wide_panel'),
              title: 'Visible Title',
              icon: const Icon(Icons.chevron_left),
              width: 300,
              child: const SizedBox.expand(),
            ),
          ],
        ),
      ),
    );

    expect(find.text('Visible Title'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
