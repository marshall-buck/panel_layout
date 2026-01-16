import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/panel_layout.dart';
import 'package:panel_layout/src/widgets/animated_panel.dart';

Finder findPanel(String id) => find.byWidgetPredicate(
  (w) => w is AnimatedPanel && w.config.id == PanelId(id),
);

void main() {
  testWidgets('Dragging handle resizes Fixed panel and triggers callbacks', (
    tester,
  ) async {
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
                InlinePanel(
                  id: const PanelId('left'),
                  width: 100,
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

    await tester.drag(handle, const Offset(50, 0));
    await tester.pump();

    expect(tester.getSize(findPanel('left')).width, 150.0);
    expect(started, true);
    expect(ended, true);
  });
}
