import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/panel_layout.dart';
import 'package:panel_layout/src/widgets/animated_panel.dart';

Finder findPanel(String id) => find.byWidgetPredicate(
  (w) => w is AnimatedPanel && w.config.id == PanelId(id),
);

void main() {
  testWidgets('Panel animates to collapsed size', (tester) async {
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
              children: [
                InlinePanel(
                  id: const PanelId('p1'),
                  width: 100,
                  toggleIconSize: 20,
                  toggleIconPadding: 0,
                  child: Container(),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(findPanel('p1')).width, 100.0);

    controller.toggleCollapsed(const PanelId('p1'));

    // Halfway (Wait for re-layout animation)
    // Wait! Collapsing currently triggers _animatePanel(id, visible)
    // which drives the visual factor (0..1).
    // If it was already visible, factor stays 1.0.

    // BUT! effectiveSize uses config.collapsedSize if state.collapsed is true.

    await tester.pumpAndSettle();
    expect(tester.getSize(findPanel('p1')).width, 20.0);
  });
}
