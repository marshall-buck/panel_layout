import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/panel_layout.dart';
import 'package:panel_layout/src/widgets/internal/panel_resize_handle.dart';

void main() {
  group('Flexible Panel Resizing', () {
    testWidgets('Resizing two flexible panels uses correct sensitivity', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PanelLayout(
              children: [
                InlinePanel(
                  id: PanelId('left'),
                  flex: 1,
                  child: Container(color: Colors.red),
                ),
                InlinePanel(
                  id: PanelId('right'),
                  flex: 1,
                  child: Container(color: Colors.blue),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Total width is 800 (default test screen width).
      // Handle width is 8.0.
      // Available space = 792.0.
      // Both flex: 1, so each should be 396.0.
      expect(tester.getSize(find.byType(PanelLayout)).width, 800.0);
      expect(tester.getSize(find.byType(Container).first).width, 396.0);

      final handle = find.byType(PanelResizeHandle);

      // Drag 100 pixels to the right.
      // Left panel should increase by 100px (to 496px).
      // Right panel should decrease by 100px (to 296px).
      await tester.drag(handle, const Offset(100, 0));
      await tester.pumpAndSettle();

      final leftPanel = find.byWidgetPredicate(
        (widget) => widget is Container && widget.color == Colors.red,
      );
      final rightPanel = find.byWidgetPredicate(
        (widget) => widget is Container && widget.color == Colors.blue,
      );

      expect(
        tester.getSize(leftPanel).width,
        closeTo(496.0, 0.5),
        reason: "Left panel should grow by 100px",
      );
      expect(
        tester.getSize(rightPanel).width,
        closeTo(296.0, 0.5),
        reason: "Right panel should shrink by 100px",
      );
    });

    testWidgets('Flexible panel resize respects minSize constraints', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PanelLayout(
              children: [
                InlinePanel(
                  id: PanelId('left'),
                  flex: 1,
                  minSize: 350.0, // Should stop shrinking at 350px
                  child: Container(color: Colors.red),
                ),
                InlinePanel(
                  id: PanelId('right'),
                  flex: 1,
                  child: Container(color: Colors.blue),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initial: 400 | 400

      final handle = find.byType(PanelResizeHandle);

      // Drag left by 100px. Left panel target would be 300px.
      // But minSize is 350px.
      await tester.drag(handle, const Offset(-100, 0));
      await tester.pumpAndSettle();

      final leftPanel = find.byWidgetPredicate(
        (widget) => widget is Container && widget.color == Colors.red,
      );

      expect(
        tester.getSize(leftPanel).width,
        closeTo(350.0, 0.5),
        reason: "Left panel should be clamped to minSize 350",
      );
    });
  });
}
