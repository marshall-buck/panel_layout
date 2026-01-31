import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_panels/flutter_panels.dart';
import 'package:flutter_panels/src/widgets/internal/panel_resize_handle.dart';
import 'package:flutter_panels/src/widgets/animation/animated_panel.dart';
import '../utils/test_content_panel.dart';

void main() {
  group('Extended Interactions', () {
    testWidgets('Resizing enforces minSize and maxSize', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 800,
              height: 100,
              child: PanelArea(
                children: [
                  InlinePanel(
                    id: const PanelId('left'),
                    width: 100,
                    minSize: 50,
                    maxSize: 150,
                    child: Container(),
                  ),
                  TestContentPanel(
                    id: const PanelId('right'),
                    layoutWeightOverride: 1,
                    child: Container(),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final handle = find.byType(PanelResizeHandle);

      // 1. Drag beyond maxSize
      await tester.drag(handle, const Offset(200, 0));
      await tester.pump();
      expect(tester.getSize(find.byType(AnimatedPanel).first).width, 150.0);

      // 2. Drag beyond minSize
      await tester.drag(handle, const Offset(-300, 0));
      await tester.pump();
      expect(tester.getSize(find.byType(AnimatedPanel).first).width, 50.0);
    });
  });
}
