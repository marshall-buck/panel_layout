import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/panel_layout.dart';
import 'package:panel_layout/src/widgets/animated_panel.dart';

class ContentPanel extends BasePanel {
  ContentPanel({super.key, required String id, required super.child})
    : super(id: PanelId(id), mode: PanelMode.inline);
}

Finder findPanel(String id) => find.byWidgetPredicate(
  (w) => w is AnimatedPanel && w.config.id == PanelId(id),
);

class SimplePanel extends BasePanel {
  SimplePanel({super.key, required String id, super.flex, required super.child})
    : super(id: PanelId(id));
}

void main() {
  testWidgets('Content sizing panel expands to fit child', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 800,
            height: 600,
            child: PanelLayout(
              children: [
                ContentPanel(
                  id: 'c1',
                  child: const SizedBox(width: 123, height: 100),
                ),
                SimplePanel(id: 'fill', flex: 1, child: Container()),
              ],
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(findPanel('c1')).width, 123.0);
  });
}
