import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/panel_layout.dart';
import 'package:panel_layout/src/layout_panel.dart';
import 'package:panel_layout/src/panel_resize_handle.dart';

void main() {
  testWidgets('Panel with ContentSizing animates when toggling visibility', (
    tester,
  ) async {
    final controller = PanelLayoutController();
    const panelId1 = PanelId('panel_1');
    const panelId2 = PanelId('test_panel');

    // Panel 1: Fixed, Visible
    controller.registerPanel(
      panelId1,
      sizing: const FixedSizing(100),
      mode: PanelMode.inline,
      anchor: PanelAnchor.right,
      isVisible: true,
    );

    // Panel 2: Content, Invisible initially
    controller.registerPanel(
      panelId2,
      sizing: const ContentSizing(),
      mode: PanelMode.inline,
      anchor: PanelAnchor.right,
      isVisible: false,
      visuals: const PanelVisuals(animationCurve: Curves.linear),
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: PanelScope(
          controller: controller,
          child: Center(
            child: SizedBox(
              height: 400,
              width: 400,
              child: PanelArea(
                panelLayoutController: controller,
                panelIds: const [panelId1, panelId2],
                panelBuilder: (context, id) {
                  if (id == panelId1) {
                    return Container(color: const Color(0xFF00FF00));
                  }
                  return Container(
                    width: 200,
                    height: 200,
                    color: const Color(0xFFFF0000),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    // Initial state:
    // Panel 1 (Visible)
    // Panel 2 (Invisible)
    // List: [LayoutPanel(1), LayoutPanel(2)]

    // Find LayoutPanel for Panel 2
    final layoutPanels = find.byType(LayoutPanel);
    expect(layoutPanels, findsNWidgets(2));
    expect(find.byType(PanelResizeHandle), findsNothing);

    final panel2Finder = layoutPanels.at(1);

    // Initial size should be 0
    expect(tester.getSize(panel2Finder).width, 0.0);

    // Set visible = true
    controller.getPanel(panelId2)!.setVisible(visible: true);
    await tester.pump(); // Start animation (frame 0)

    // Check ResizeHandle exists
    expect(find.byType(PanelResizeHandle), findsOneWidget);

    // Find the new panel finder (it might have moved)
    final panel2FinderNew = find.byType(LayoutPanel).last;

    // Check size at 0ms.

    // If state is preserved, it should be 0 (start of animation).

    // If state is lost (recreated widget), it would jump to 200.

    final size0ms = tester.getSize(panel2FinderNew);

    // Pump 150ms (halfway of 300ms linear)

    await tester.pump(const Duration(milliseconds: 150));

    final Size sizeMid = tester.getSize(panel2FinderNew);

    // Pump until done

    await tester.pumpAndSettle();

    final Size sizeFinal = tester.getSize(panel2FinderNew);

    expect(sizeFinal.width, 200.0);

    // Regression check: Ensure animation starts from 0 and progresses.

    expect(size0ms.width, 0.0, reason: 'Should start at 0');

    expect(sizeMid.width, 100.0, reason: 'Should be 100 at 50%');
  });
}
