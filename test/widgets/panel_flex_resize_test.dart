import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_panels/flutter_panels.dart';
import 'package:flutter_panels/src/widgets/internal/panel_resize_handle.dart';
import '../utils/test_content_panel.dart';

void main() {
  group('Flexible Panel Resizing', () {
    testWidgets('No resize handle between two InternalLayoutAdapter panels', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PanelArea(
              children: [
                TestContentPanel(
                  id: PanelId('left'),
                  layoutWeightOverride: 1,
                  child: Container(color: Colors.red),
                ),
                TestContentPanel(
                  id: PanelId('right'),
                  layoutWeightOverride: 1,
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
