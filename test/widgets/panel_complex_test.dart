import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/panel_layout.dart';
import 'package:panel_layout/src/widgets/internal/panel_resize_handle.dart';
import 'package:panel_layout/src/widgets/animation/animated_panel.dart';
import '../utils/test_content_panel.dart';

Finder findPanel(String id) => find.byWidgetPredicate(
  (w) => w is AnimatedPanel && w.config.id == PanelId(id),
);

void main() {
  group('PanelLayout Complex Scenarios', () {
    testWidgets('zIndex controls child order (paint order)', (tester) async {
      final List<String> buildOrder = [];

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PanelLayout(
            children: [
              OverlayPanel(
                id: const PanelId('high'),
                zIndex: 10,

                child: Builder(
                  builder: (context) {
                    buildOrder.add('high');
                    return const SizedBox(width: 100, height: 100);
                  },
                ),
              ),
              OverlayPanel(
                id: const PanelId('low'),
                zIndex: 1,

                child: Builder(
                  builder: (context) {
                    buildOrder.add('low');
                    return const SizedBox(width: 100, height: 100);
                  },
                ),
              ),
            ],
          ),
        ),
      );

      // ASC order: low (1), then high (10).
      expect(buildOrder, ['low', 'high']);
    });

    testWidgets('PanelLayoutController toggles visibility', (tester) async {
      final controller = PanelLayoutController();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PanelLayout(
            controller: controller,
            children: [
              InlinePanel(
                id: const PanelId('p1'),
                width: 100,
                child: const Text('Panel 1'),
              ),
            ],
          ),
        ),
      );

      expect(find.text('Panel 1'), findsOneWidget);
      expect(tester.getSize(findPanel('p1')).width, 100.0);

      controller.setVisible(const PanelId('p1'), false);
      await tester.pumpAndSettle();

      expect(tester.getSize(findPanel('p1')).width, 0.0);
    });

    testWidgets('State persists across widget instance rebuilds', (
      tester,
    ) async {
      Widget buildLayout(double initialWidth) {
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 400,
              height: 100,
              child: PanelLayout(
                children: [
                  InlinePanel(
                    id: const PanelId('left'),
                    width: initialWidth,
                    child: Container(),
                  ),
                  TestContentPanel(
                    id: const PanelId('right'),
                    flexOverride: 1,
                    child: Container(),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      // 1. Initial build
      await tester.pumpWidget(buildLayout(100));
      expect(tester.getSize(findPanel('left')).width, 100.0);

      // 2. Resize via drag
      final handle = find.byType(PanelResizeHandle);
      await tester.drag(handle, const Offset(50, 0));
      await tester.pump();
      expect(tester.getSize(findPanel('left')).width, 150.0);

      // 3. Rebuild with DIFFERENT initialWidth in config (but same ID)
      await tester.pumpWidget(buildLayout(200));

      expect(tester.getSize(findPanel('left')).width, 150.0);
    });

    testWidgets('PanelLayout handles controller swap', (tester) async {
      final c1 = PanelLayoutController();
      final c2 = PanelLayoutController();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PanelLayout(
            controller: c1,
            children: [
              InlinePanel(
                id: const PanelId('p1'),
                width: 100,
                child: Container(),
              ),
            ],
          ),
        ),
      );

      // Swap controller
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PanelLayout(
            controller: c2,
            children: [
              InlinePanel(
                id: const PanelId('p1'),
                width: 100,
                child: Container(),
              ),
            ],
          ),
        ),
      );

      // Verify c2 works
      c2.setVisible(const PanelId('p1'), false);
      await tester.pumpAndSettle();
      expect(tester.getSize(findPanel('p1')).width, 0.0);
    });
  });
}
