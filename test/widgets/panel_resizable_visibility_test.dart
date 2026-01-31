import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_panels/flutter_panels.dart';
import 'package:flutter_panels/src/widgets/internal/panel_resize_handle.dart';

void main() {
  testWidgets('Resize handle icon is hidden when panels are not resizable', (
    tester,
  ) async {
    const handleIcon = Icons.drag_handle;

    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: Scaffold(
            body: PanelArea(
              style: const PanelStyle(handleIcon: handleIcon),
              children: [
                InlinePanel(
                  id: const PanelId('p1'),
                  width: 200,
                  resizable: false,
                  child: const SizedBox(),
                ),
                InlinePanel(
                  id: const PanelId('p2'),
                  width: 200,
                  resizable: false,
                  child: const SizedBox(),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Verify handle is present (for the line)
    expect(find.byType(PanelResizeHandle), findsOneWidget);

    // Verify icon is NOT present
    expect(find.byIcon(handleIcon), findsNothing);
  });

  testWidgets(
    'Resize handle icon IS shown when at least one panel is resizable',
    (tester) async {
      const handleIcon = Icons.drag_handle;

      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.ltr,
            child: Scaffold(
              body: PanelArea(
                style: const PanelStyle(handleIcon: handleIcon),
                children: [
                  InlinePanel(
                    id: const PanelId('p1'),
                    width: 200,
                    resizable: true,
                    child: const SizedBox(),
                  ),
                  InlinePanel(
                    id: const PanelId('p2'),
                    width: 200,
                    resizable: false,
                    child: const SizedBox(),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify handle is present
      expect(find.byType(PanelResizeHandle), findsOneWidget);

      // Verify icon IS present because 'p1' is fixed and resizable (Case 1)
      expect(find.byIcon(handleIcon), findsOneWidget);
    },
  );

  testWidgets('Resize handle cursor is defer when not resizable', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: TextDirection.ltr,
          child: Scaffold(
            body: PanelArea(
              children: [
                InlinePanel(
                  id: const PanelId('p1'),
                  width: 200,
                  resizable: false,
                  child: const SizedBox(),
                ),
                InlinePanel(
                  id: const PanelId('p2'),
                  width: 200,
                  resizable: false,
                  child: const SizedBox(),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final mouseRegion = tester.widget<MouseRegion>(
      find.descendant(
        of: find.byType(PanelResizeHandle),
        matching: find.byType(MouseRegion),
      ),
    );

    expect(mouseRegion.cursor, MouseCursor.defer);
  });

  testWidgets(
    'Resize handle cursor is resizeColumn when resizable horizontally',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.ltr,
            child: Scaffold(
              body: PanelArea(
                children: [
                  InlinePanel(
                    id: const PanelId('p1'),
                    width: 200,
                    resizable: true,
                    child: const SizedBox(),
                  ),
                  InlinePanel(
                    id: const PanelId('p2'),
                    width: 200,
                    resizable: true,
                    child: const SizedBox(),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final mouseRegion = tester.widget<MouseRegion>(
        find.descendant(
          of: find.byType(PanelResizeHandle),
          matching: find.byType(MouseRegion),
        ),
      );

      expect(mouseRegion.cursor, SystemMouseCursors.resizeColumn);
    },
  );
}
