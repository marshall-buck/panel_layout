import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/panel_layout.dart';
import 'package:panel_layout/src/widgets/animation/animated_panel.dart';
import '../utils/test_content_panel.dart';

void main() {
  testWidgets('Nested PanelLayouts work correctly', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 800,
            height: 600,
            child: PanelLayout(
              children: [
                InlinePanel(
                  id: const PanelId('sidebar'),
                  width: 200,
                  child: PanelLayout(
                    children: [
                      InlinePanel(
                        id: const PanelId('top'),
                        anchor: PanelAnchor.top,
                        height: 100,
                        child: Container(),
                      ),
                      TestContentPanel(
                        id: const PanelId('bottom'),
                        // anchor: PanelAnchor.top, // UserContent doesn't support anchor in same way? Wait. UserContent IS InlinePanel.
                        // InlinePanel supports anchor.
                        // But TestContentPanel constructor doesn't expose anchor?
                        // Let's check TestContentPanel again.
                        child: Container(),
                      ),
                    ],
                  ),
                ),
                TestContentPanel(
                  id: const PanelId('main'),
                  child: Container(),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Verify outer sidebar width
    expect(
      tester
          .getSize(
            find.byWidgetPredicate(
              (w) =>
                  w is AnimatedPanel && w.config.id == const PanelId('sidebar'),
            ),
          )
          .width,
      200.0,
    );

    // Verify inner panels
    expect(
      tester
          .getSize(
            find.byWidgetPredicate(
              (w) => w is AnimatedPanel && w.config.id == const PanelId('top'),
            ),
          )
          .height,
      100.0,
    );
    expect(
      tester
          .getSize(
            find.byWidgetPredicate(
              (w) =>
                  w is AnimatedPanel && w.config.id == const PanelId('bottom'),
            ),
          )
          .height,
      492.0,
    ); // 600 - 100 - 8 (handle)
  });
}
