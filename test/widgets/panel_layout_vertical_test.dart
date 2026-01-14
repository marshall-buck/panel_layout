import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/panel_layout.dart';
import 'package:panel_layout/src/widgets/animated_panel.dart';

class TestFixedPanel extends BasePanel {
  TestFixedPanel({super.key, required String id, required double height})
    : super(
        id: PanelId(id),
        height: height,
        mode: PanelMode.inline,
        anchor: PanelAnchor.top,
        child: Container(),
      );
}

void main() {
  testWidgets('PanelLayout vertical axis sizes correctly', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 100,
            height: 400,
            child: PanelLayout(
              axis: Axis.vertical,
              children: [
                TestFixedPanel(id: 't1', height: 100),
                TestFixedPanel(id: 't2', height: 200),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(AnimatedPanel).first).height, 100.0);
    expect(tester.getSize(find.byType(AnimatedPanel).last).height, 200.0);
  });
}
