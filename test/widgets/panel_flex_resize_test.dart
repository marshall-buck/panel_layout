import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/panel_layout.dart';
import 'package:panel_layout/src/widgets/internal/panel_resize_handle.dart';
import '../utils/test_content_panel.dart';

void main() {
  group('Flexible Panel Resizing', () {
    testWidgets('No resize handle between two InternalLayoutAdapter panels', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PanelLayout(
              children: [
                TestContentPanel(
                  id: PanelId('left'),
                  flexOverride: 1,
                  child: Container(color: Colors.red),
                ),
                TestContentPanel(
                  id: PanelId('right'),
                  flexOverride: 1,
                  child: Container(color: Colors.blue),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify no handle is present
      expect(find.byType(PanelResizeHandle), findsNothing);
    });


  });
}
