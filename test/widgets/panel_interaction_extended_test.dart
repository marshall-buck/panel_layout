import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/panel_layout.dart';
import 'package:panel_layout/src/widgets/internal/panel_resize_handle.dart';
import 'package:panel_layout/src/widgets/animation/animated_panel.dart';

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
              child: PanelLayout(
                children: [
                  InlinePanel(
                    id: const PanelId('left'),
                    width: 100,
                    minSize: 50,
                    maxSize: 150,
                    child: Container(),
                  ),
                  InlinePanel(
                    id: const PanelId('right'),
                    flex: 1,
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

    testWidgets('Flex-Flex resizing updates weights', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 400,
              height: 100,
              child: PanelLayout(
                children: [
                  InlinePanel(
                    id: const PanelId('f1'),
                    flex: 1,
                    child: Container(),
                  ),
                  InlinePanel(
                    id: const PanelId('f2'),
                    flex: 1,
                    child: Container(),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // 400 - 8 (handle) = 392. Initial: 196 each.
      expect(tester.getSize(find.byType(AnimatedPanel).first).width, 196.0);

      final handle = find.byType(PanelResizeHandle);

      // Drag right by 50px
      await tester.drag(handle, const Offset(50, 0));
      await tester.pump();

      final w1 = tester.getSize(find.byType(AnimatedPanel).first).width;
      final w2 = tester.getSize(find.byType(AnimatedPanel).last).width;

      expect(w1, greaterThan(196.0));
      expect(w2, lessThan(196.0));
      expect(w1 + w2, closeTo(392.0, 0.1));
    });
  });
}
