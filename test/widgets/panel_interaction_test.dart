import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/panel_layout.dart';
import 'package:panel_layout/src/widgets/animated_panel.dart';

class TestFixedPanel extends BasePanel {
  TestFixedPanel({
    super.key,
    required String id,
    required double width,
  }) : super(id: PanelId(id), width: width, mode: PanelMode.inline, child: Container());
}

class TestFlexPanel extends BasePanel {
  TestFlexPanel({
    super.key,
    required String id,
    double flex = 1.0,
  }) : super(id: PanelId(id), flex: flex, mode: PanelMode.inline, child: Container());
}

Finder findPanel(String id) => find.byWidgetPredicate((w) => w is AnimatedPanel && w.config.id == PanelId(id));

void main() {
  testWidgets('Dragging handle resizes Fixed panel and triggers callbacks', (tester) async {
    bool started = false;
    bool ended = false;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 400,
            height: 100,
            child: PanelLayout(
              onResizeStart: () => started = true,
              onResizeEnd: () => ended = true,
              children: [
                TestFixedPanel(id: 'left', width: 100),
                TestFlexPanel(id: 'right', flex: 1),
              ],
            ),
          ),
        ),
      ),
    );

    final handle = find.byType(PanelResizeHandle);
    
    await tester.drag(handle, const Offset(50, 0));
    await tester.pump();

    expect(tester.getSize(findPanel('left')).width, 150.0);
    expect(started, true);
    expect(ended, true);
  });
}