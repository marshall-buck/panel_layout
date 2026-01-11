import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/panel_layout.dart';
import 'package:panel_layout/src/widgets/animated_panel.dart';

// --- Test Helpers ---
class TestFixedPanel extends BasePanel {
  TestFixedPanel({
    super.key,
    required String id,
    required double width,
    Color color = const Color(0xFFFF0000),
  }) : super(
    id: PanelId(id),
    width: width,
    mode: PanelMode.inline,
    child: Container(color: color),
  );
}

class TestFlexPanel extends BasePanel {
  TestFlexPanel({
    super.key,
    required String id,
    double flex = 1.0,
    Color color = const Color(0xFF00FF00),
  }) : super(
    id: PanelId(id),
    flex: flex,
    mode: PanelMode.inline,
    child: Container(color: color),
  );
}

Finder findPanel(String id) => find.byWidgetPredicate((w) => w is AnimatedPanel && w.config.id == PanelId(id));

void main() {
  testWidgets('PanelLayout renders fixed panels with correct width', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            height: 100,
            width: 800, 
            child: PanelLayout(
              children: [
                TestFixedPanel(id: 'p1', width: 100),
                TestFixedPanel(id: 'p2', width: 200),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(findPanel('p1')).width, 100.0);
    expect(tester.getSize(findPanel('p2')).width, 200.0);
  });

  testWidgets('PanelLayout distributes flex space accounting for handle', (tester) async {
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
                TestFlexPanel(id: 'f2', flex: 3),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(findPanel('f1')).width, 98.0);
    expect(tester.getSize(findPanel('f2')).width, 294.0);
  });
  
  testWidgets('PanelLayout mixes Fixed and Flex panels', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 500,
            height: 100,
            child: PanelLayout(
              children: [
                TestFixedPanel(id: 'fixed', width: 100),
                TestFlexPanel(id: 'flex', flex: 1),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(findPanel('fixed')).width, 100.0);
    expect(tester.getSize(findPanel('flex')).width, 392.0);
  });
}