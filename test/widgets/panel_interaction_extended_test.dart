import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/panel_layout.dart';
import 'package:panel_layout/src/widgets/animated_panel.dart';

class TestFixedPanel extends BasePanel {
  TestFixedPanel({
    super.key,
    required String id,
    required double width,
    super.minSize,
    super.maxSize,
  }) : super(
         id: PanelId(id),
         width: width,
         mode: PanelMode.inline,
         child: Container(),
       );
}

class TestFlexPanel extends BasePanel {
  TestFlexPanel({super.key, required String id, double flex = 1.0})
    : super(
        id: PanelId(id),
        flex: flex,
        mode: PanelMode.inline,
        child: Container(),
      );
}

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
                  TestFixedPanel(
                    id: 'left',
                    width: 100,
                    minSize: 50,
                    maxSize: 150,
                  ),
                  TestFlexPanel(id: 'right', flex: 1),
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
                  TestFlexPanel(id: 'f1', flex: 1),
                  TestFlexPanel(id: 'f2', flex: 1),
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
