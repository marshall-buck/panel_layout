import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_panels/flutter_panels.dart';
import 'package:flutter_panels/src/widgets/internal/panel_resize_handle.dart';
import '../utils/test_content_panel.dart';

void main() {
  group('Panel Resize Constraints', () {
    testWidgets('Cannot resize a collapsed panel', (tester) async {
      final controller = PanelAreaController();
      final panelId = PanelId('sidebar');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PanelArea(
              controller: controller,
              children: [
                InlinePanel(
                  id: panelId,
                  width: 200,
                  initialCollapsed: true, // Start collapsed
                  child: Container(color: Colors.red),
                ),
                TestContentPanel(
                  id: PanelId('main'),
                  layoutWeightOverride: 1,
                  child: Container(color: Colors.blue),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find the resize handle
      final handle = find.byType(PanelResizeHandle);
      expect(handle, findsOneWidget);

      // Attempt to drag the handle
      await tester.drag(handle, const Offset(50, 0));
      await tester.pumpAndSettle();

      // The panel should NOT have expanded (should remain at collapsed size)
      // We check if the size is still 200 (meaning the expanded size state didn't change)
      // Note: We can't easily check visual width without expanding, but we can verify the state hasn't drifted.

      controller.setCollapsed(panelId, false);
      await tester.pumpAndSettle();

      final containerFinder = find.byWidgetPredicate(
        (widget) => widget is Container && widget.color == Colors.red,
      );
      final size = tester.getSize(containerFinder);

      expect(
        size.width,
        200.0,
        reason:
            "Panel size should remain 200 after attempting resize while collapsed",
      );
    });

    testWidgets('Cannot resize panel smaller than collapsed size (rail width)', (
      tester,
    ) async {
      final panelId = PanelId('sidebar');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PanelArea(
              children: [
                InlinePanel(
                  id: panelId,
                  width: 100, // Small width, close to rail limit
                  child: Container(color: Colors.red),
                ),
                TestContentPanel(
                  id: PanelId('main'),
                  layoutWeightOverride: 1,
                  child: Container(color: Colors.blue),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final handle = find.byType(PanelResizeHandle);

      // Drag left to shrink. Try to shrink by 80px (target 20px).
      // Since rail size is 42px (IconSize 24 + RailPadding 18), it should stop there.
      await tester.drag(handle, const Offset(-80, 0));
      await tester.pumpAndSettle();

      final containerFinder = find.byWidgetPredicate(
        (widget) => widget is Container && widget.color == Colors.red,
      );
      final size = tester.getSize(containerFinder);

      // Expected minimum is typically iconSize (24) + railPadding (18) = 42.
      expect(size.width, greaterThanOrEqualTo(42.0));
      expect(size.width, 42.0, reason: "Should clamp to rail size");
    });
  });
}
