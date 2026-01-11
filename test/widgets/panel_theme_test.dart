import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/panel_layout.dart';
import 'package:panel_layout/src/widgets/animated_panel.dart';

class SimplePanel extends BasePanel {
  SimplePanel({super.key, required String id, super.width, required super.child}) : super(id: PanelId(id));
}

Finder findPanel(String id) => find.byWidgetPredicate((w) => w is AnimatedPanel && w.config.id == PanelId(id));

void main() {
  testWidgets('ResizeHandleTheme affects handle size and layout', (tester) async {
    const handleWidth = 20.0;
    const hitTestWidth = 30.0;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ResizeHandleTheme(
          data: const ResizeHandleThemeData(
            width: handleWidth,
            hitTestWidth: hitTestWidth,
          ),
          child: Center(
            child: SizedBox(
              width: 500,
              height: 100,
              child: PanelLayout(
                children: [
                  SimplePanel(id: 'p1', width: 100, child: Container()),
                  SimplePanel(id: 'p2', width: 100, child: Container()),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final p1 = tester.getRect(findPanel('p1'));
    final p2 = tester.getRect(findPanel('p2'));

    // Space between panels should be equal to hitTestWidth (not visible width)
    // because PanelResizeHandle uses hitTestWidth for its layout size.
    expect(p2.left - p1.right, hitTestWidth);
    
    // Verify handle size
    final handle = tester.getSize(find.byType(PanelResizeHandle));
    expect(handle.width, hitTestWidth);
  });
}
