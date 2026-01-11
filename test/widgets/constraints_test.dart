import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/panel_layout.dart';

void main() {
  group('PanelArea Layout Constraints', () {
    testWidgets('Overlay with CrossAxisAlignment.stretch matches anchor height', (tester) async {
      final controller = PanelLayoutController();
      const anchorId = PanelId('anchor');
      const overlayId = PanelId('overlay');

      // Anchor Panel: 200px Height
      controller.registerPanel(
        anchorId,
        builder: (context, _) => SizedBox(width: 100, height: 200),
        sizing: const FixedSizing(100),
        mode: PanelMode.inline,
        anchor: PanelAnchor.right,
      );

      // Overlay Panel: Content is only 50px high
      // But it is anchored Left and Stretches
      controller.registerPanel(
        overlayId,
        builder: (context, _) => SizedBox(width: 50, height: 50),
        sizing: const FixedSizing(50),
        mode: PanelMode.overlay,
        anchor: PanelAnchor.left,
        anchorPanel: anchorId,
        crossAxisAlignment: CrossAxisAlignment.stretch, // Default
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 800,
            height: 600,
            child: PanelArea(
              panelLayoutController: controller,
              panelIds: const [anchorId, overlayId],
            ),
          ),
        ),
      );

      // Verify Anchor Height
      final anchorSize = tester.getSize(find.byKey(ValueKey(anchorId)));
      expect(anchorSize.height, 200.0);

      // Verify Overlay Height
      // It should be 200.0 (stretched), not 50.0 (content)
      final overlaySize = tester.getSize(find.byKey(ValueKey(overlayId)));
      expect(overlaySize.height, 200.0, reason: 'Overlay should stretch to match anchor height');
    });
  });
}
