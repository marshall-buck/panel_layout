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
      'Global Overlay respects custom alignment and crossAxisAlignment',
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
          crossAxisAlignment:
              CrossAxisAlignment.center, // Don't stretch to full width
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

        // Verify alignment
        final alignFinder = find.ancestor(
          of: find.text('Dropdown'),
          matching: find.byType(Align),
        );
        expect(alignFinder, findsOneWidget);
        expect(
          tester.widget<Align>(alignFinder).alignment,
          Alignment.topCenter,
        );

        // Verify it is NOT stretched
        // We find the Flex that is the parent of the panel
        final flexFinder = find
            .ancestor(of: find.text('Dropdown'), matching: find.byType(Flex))
            .first;

        expect(
          tester.widget<Flex>(flexFinder).crossAxisAlignment,
          CrossAxisAlignment.center,
        );
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
