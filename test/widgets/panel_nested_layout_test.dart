import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/panel_layout.dart';
import 'package:panel_layout/src/widgets/animated_panel.dart';

class OuterPanel extends BasePanel {
  OuterPanel({super.key, required String id, super.width, required super.child})
    : super(id: PanelId(id));
}

class SimplePanel extends BasePanel {
  SimplePanel({
    super.key,
    required String id,
    super.height,
    super.flex,
    required super.child,
  }) : super(id: PanelId(id));
}

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
                OuterPanel(
                  id: 'sidebar',
                  width: 200,
                  child: PanelLayout(
                    axis: Axis.vertical,
                    children: [
                      SimplePanel(id: 'top', height: 100, child: Container()),
                      SimplePanel(id: 'bottom', flex: 1, child: Container()),
                    ],
                  ),
                ),
                SimplePanel(id: 'main', flex: 1, child: Container()),
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
