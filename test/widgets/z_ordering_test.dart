import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/panel_layout.dart';

void main() {
  testWidgets(
    'Panel zIndex determines paint order irrespective of panelIds order',
    (tester) async {
      final controller = PanelLayoutController();

      // Create 3 panels
      // Panel A: Inline (Bottom Layer) -> zIndex 0
      // Panel B: Overlay (Behind A? No, let's say Top) -> zIndex 10
      // Panel C: Overlay (Behind B but above A) -> zIndex 5

      final idA = PanelId('panelA');
      final idB = PanelId('panelB');
      final idC = PanelId('panelC');

      controller.registerPanel(
        idA,
        builder: (c, _) => const Text('A'),
        sizing: const FixedSizing(100),
        mode: PanelMode.inline,
        anchor: PanelAnchor.left,
        // zIndex: 0, // Default
      );

      controller.registerPanel(
        idB,
        builder: (c, _) => const Text('B'),
        sizing: const FixedSizing(100),
        mode: PanelMode.overlay,
        anchor: PanelAnchor.left,
        zIndex: 10,
      );

      controller.registerPanel(
        idC,
        builder: (c, _) => const Text('C'),
        sizing: const FixedSizing(100),
        mode: PanelMode.overlay,
        anchor: PanelAnchor.left,
        zIndex: 5,
      );

      // Order in panelIds: A, B, C
      // Expected Paint Order (zIndex): A (0), C (5), B (10)

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PanelArea(
            panelLayoutController: controller,
            panelIds: [idA, idB, idC],
          ),
        ),
      );

      // Verify CustomMultiChildLayout children order
      final layoutFinder = find.byType(CustomMultiChildLayout);
      final layout = tester.widget<CustomMultiChildLayout>(layoutFinder);

      // The children list of CustomMultiChildLayout determines paint order.
      expect(layout.children.length, 3);

      expect(getId(layout.children[0]), idA); // zIndex 0
      expect(getId(layout.children[1]), idC); // zIndex 5
      expect(getId(layout.children[2]), idB); // zIndex 10
    },
  );

  testWidgets('Handles render on top of panels with same zIndex', (
    tester,
  ) async {
    final controller = PanelLayoutController();

    final idA = PanelId('panelA');
    final idB = PanelId('panelB');

    controller.registerPanel(
      idA,
      builder: (c, _) => const Text('A'),
      sizing: const FixedSizing(100),
      mode: PanelMode.inline,
      anchor: PanelAnchor.left,
      isResizable: true,
    );

    controller.registerPanel(
      idB,
      builder: (c, _) => const Text('B'),
      sizing: const FixedSizing(100),
      mode: PanelMode.inline,
      anchor: PanelAnchor.left,
      isResizable: true,
    );

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: PanelArea(
          panelLayoutController: controller,
          panelIds: [idA, idB],
        ),
      ),
    );

    final layout = tester.widget<CustomMultiChildLayout>(
      find.byType(CustomMultiChildLayout),
    );

    // Expected: Panel A, Panel B, Handle
    // Panels A and B have zIndex 0. Handle has zIndex 0.
    // Handle isHandle=true, so it sorts after Panels.

    expect(layout.children.length, 3);

    expect(getId(layout.children[0]), idA);
    expect(getId(layout.children[1]), idB);

    // Last one should be handle
    final last = layout.children[2];
    expect(last is LayoutId, true);
    if (last is LayoutId) {
      // Handle ID is _HandleId, not PanelId.
      expect(last.id is PanelId, false);
    }
  });
}

PanelId getId(Widget w) {
  if (w is LayoutId) {
    if (w.id is PanelId) return w.id as PanelId;
  }
  return PanelId('unknown');
}
