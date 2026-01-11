import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/panel_layout.dart';
import 'package:panel_layout/src/widgets/animated_panel.dart';

class TestFixedPanel extends BasePanel {
  TestFixedPanel({super.key, required String id, required double width})
    : super(
        id: PanelId(id),
        width: width,
        mode: PanelMode.inline,
        child: Container(),
      );
}

void main() {
  testWidgets('Panel animates size when hidden', (tester) async {
    final controller = PanelLayoutController();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 400,
            height: 100,
            child: PanelLayout(
              controller: controller,
              children: [TestFixedPanel(id: 'p1', width: 100)],
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(TestFixedPanel)).width, 100.0);

    controller.setVisible(const PanelId('p1'), false);

    // Start animation
    await tester.pump();

    // Halfway (Default is 250ms)
    await tester.pump(const Duration(milliseconds: 125));
    final intermediateWidth = tester.getSize(find.byType(AnimatedPanel)).width;
    expect(intermediateWidth, closeTo(50.0, 1.0));

    // End
    await tester.pump(const Duration(milliseconds: 125));
    expect(tester.getSize(find.byType(AnimatedPanel)).width, 0.0);
  });
}
