import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/panel_layout.dart';

void main() {
  group('PanelArea Custom Overlay', () {
    late PanelLayoutController layoutController;

    setUp(() {
      layoutController = PanelLayoutController();
    });

    tearDown(() {
      layoutController.dispose();
    });

    testWidgets(
      'Global Overlay respects custom alignment',
      (tester) async {
        layoutController.registerPanel(
          const PanelId('main'),
          builder: (context, _) => Container(color: const Color(0xFFCCCCCC)),
          sizing: const FlexibleSizing(1),
          mode: PanelMode.inline,
          anchor: PanelAnchor.left,
        );

        layoutController.registerPanel(
          const PanelId('top_center_dropdown'),
          builder: (context, _) => Container(
            width: 200,
            height: 100,
            color: const Color(0xFFFF0000),
            child: const Text('Dropdown'),
          ),
          sizing: const FixedSizing(100),
          mode: PanelMode.overlay,
          anchor: PanelAnchor.top,
          alignment: Alignment.topCenter,
          // crossAxisAlignment is handled by the Delegate logic if not stretching
        );

        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: SizedBox(
              width: 800,
              height: 600,
              child: PanelArea(
                panelLayoutController: layoutController,
                panelIds: const [
                  PanelId('main'),
                  PanelId('top_center_dropdown'),
                ],
              ),
            ),
          ),
        );

        // Verify position: Should be Top Center of 800x600.
        // X = (800 - 200) / 2 = 300.
        // Y = 0.
        
        final dropdownRect = tester.getRect(find.text('Dropdown'));
        expect(dropdownRect.left, 300.0);
        expect(dropdownRect.top, 0.0);
      },
    );

    testWidgets('Relative Overlay uses anchorLink', (tester) async {
      final layerLink = LayerLink();

      // Register panel first to ensure it's picked up
      layoutController.registerPanel(
        const PanelId('tooltip'),
        builder: (context, _) => const Text('Tooltip'),
        sizing: const ContentSizing(),
        mode: PanelMode.overlay,
        anchor: PanelAnchor.bottom, // Below target
        anchorLink: layerLink, // Anchor to the external link
      );

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 800,
            height: 600,
            child: Stack(
              children: [
                Positioned(
                  left: 100,
                  top: 100,
                  child: CompositedTransformTarget(
                    link: layerLink,
                    child: const SizedBox(width: 50, height: 50),
                  ),
                ),
                PanelArea(
                  panelLayoutController: layoutController,
                  panelIds: const [PanelId('tooltip')],
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify it is wrapped in CompositedTransformFollower linked to our link
      final followerFinder = find.ancestor(
        of: find.text('Tooltip'),
        matching: find.byType(CompositedTransformFollower),
      );
      expect(followerFinder, findsOneWidget);
      expect(
        tester.widget<CompositedTransformFollower>(followerFinder).link,
        layerLink,
      );
    });
  });
}