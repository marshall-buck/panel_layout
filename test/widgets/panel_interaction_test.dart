import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_panels/flutter_panels.dart';
import 'package:flutter_panels/src/widgets/internal/panel_resize_handle.dart';
import 'package:flutter_panels/src/widgets/animation/animated_panel.dart';
import '../utils/test_content_panel.dart';

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
            child: PanelArea(
              onResizeStart: () => started = true,
              onResizeEnd: () => ended = true,
              children: [
                InlinePanel(
                  id: const PanelId('left'),
                  width: 100,
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

    await tester.drag(handle, const Offset(50, 0));
    await tester.pump();

    expect(tester.getSize(findPanel('left')).width, 150.0);
    expect(started, true);
    expect(ended, true);
  });
}
