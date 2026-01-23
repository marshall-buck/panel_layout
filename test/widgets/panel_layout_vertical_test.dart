import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/panel_layout.dart';
import 'package:panel_layout/src/widgets/animation/animated_panel.dart';

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
              
              children: [
                InlinePanel(
                  id: const PanelId('t1'),
                  height: 100,
                  anchor: PanelAnchor.top,
                  child: Container(),
                ),
                InlinePanel(
                  id: const PanelId('t2'),
                  height: 200,
                  anchor: PanelAnchor.top,
                  child: Container(),
                ),
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
