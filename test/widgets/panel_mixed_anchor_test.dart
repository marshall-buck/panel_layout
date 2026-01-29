import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/panel_layout.dart';
import 'package:panel_layout/src/widgets/internal/panel_resize_handle.dart';
import '../utils/test_content_panel.dart';

void main() {
  group('PanelLayout Mixed Anchors', () {
    testWidgets('Vertical Layout with Neutral Center Panel works', (
      tester,
    ) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PanelLayout(
            children: [
              InlinePanel(
                id: const PanelId('top'),
                anchor: PanelAnchor.top,
                height: 50,
                child: const Text('Top'),
              ),
              TestContentPanel(
                id: const PanelId('center'),
                layoutWeightOverride: 1,
                child: const Text('Center'),
              ),
              InlinePanel(
                id: const PanelId('bottom'),
                anchor: PanelAnchor.bottom,
                height: 50,
                child: const Text('Bottom'),
              ),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Top'), findsOneWidget);
      expect(find.text('Center'), findsOneWidget);
      expect(find.text('Bottom'), findsOneWidget);
    });

    testWidgets('Horizontal Layout with Neutral Center Panel works', (
      tester,
    ) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PanelLayout(
            children: [
              InlinePanel(
                id: const PanelId('left'),
                anchor: PanelAnchor.left,
                width: 50,
                child: const Text('Left'),
              ),
              TestContentPanel(
                id: const PanelId('center'),
                layoutWeightOverride: 1,
                child: const Text('Center'),
              ),
              InlinePanel(
                id: const PanelId('right'),
                anchor: PanelAnchor.right,
                width: 50,
                child: const Text('Right'),
              ),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Left'), findsOneWidget);
      expect(find.text('Center'), findsOneWidget);
      expect(find.text('Right'), findsOneWidget);
    });

    testWidgets('Explicit Conflicting Anchors fails with AnchorException', (
      tester,
    ) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PanelLayout(
            children: [
              InlinePanel(
                id: const PanelId('top'),
                anchor: PanelAnchor.top,
                height: 50,
                child: const Text('Top'),
              ),
              InlinePanel(
                id: const PanelId('left'),
                anchor: PanelAnchor.left,
                width: 50,
                child: const Text('Left'),
              ),
            ],
          ),
        ),
      );

      final exception = tester.takeException();
      expect(exception, isA<AnchorException>());
      expect(
        exception.toString(),
        contains('PanelLayout contains InlinePanels with conflicting axes'),
      );
    });

    testWidgets('Neutral panel respects width in Horizontal layout', (
      tester,
    ) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PanelLayout(
            children: [
              InlinePanel(
                id: const PanelId('left'),
                anchor: PanelAnchor.left,
                width: 50,
                child: const SizedBox.expand(),
              ),
              InlinePanel(
                id: const PanelId('h_neutral'),
                width: 100,
                child: const SizedBox.expand(),
              ),
            ],
          ),
        ),
      );

      final neutralFinder = find.byWidgetPredicate(
        (w) => w is PanelDataScope && w.config.id == const PanelId('h_neutral'),
      );
      final neutralRect = tester.getRect(neutralFinder);
      expect(neutralRect.width, 100);
    });

    testWidgets('Neutral panel respects height in Vertical layout', (
      tester,
    ) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PanelLayout(
            children: [
              InlinePanel(
                id: const PanelId('top'),
                anchor: PanelAnchor.top,
                height: 50,
                child: const SizedBox.expand(),
              ),
              InlinePanel(
                id: const PanelId('v_neutral'),
                height: 120,
                child: const SizedBox.expand(),
              ),
            ],
          ),
        ),
      );

      final neutralFinder = find.byWidgetPredicate(
        (w) => w is PanelDataScope && w.config.id == const PanelId('v_neutral'),
      );
      final neutralRect = tester.getRect(neutralFinder);
      expect(neutralRect.height, 120);
    });

    testWidgets('Neutral panel can be collapsed (Vertical)', (tester) async {
      final controller = PanelLayoutController();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PanelLayout(
            controller: controller,
            children: [
              InlinePanel(
                id: const PanelId('top'),
                anchor: PanelAnchor.top,
                height: 50,
                child: const SizedBox.expand(),
              ),
              InlinePanel(
                id: const PanelId('collapsible_neutral'),
                height: 100,
                child: const Text('Neutral Content'),
              ),
            ],
          ),
        ),
      );

      expect(find.text('Neutral Content'), findsOneWidget);

      controller.setCollapsed(const PanelId('collapsible_neutral'), true);
      await tester.pump();
      await tester.pumpAndSettle();

      // Content should be hidden (opacity 0)
      final contentOpacity = tester.widget<Opacity>(
        find
            .ancestor(
              of: find.text('Neutral Content'),
              matching: find.byType(Opacity),
            )
            .first,
      );
      expect(contentOpacity.opacity, 0.0);
    });

    testWidgets('Resize handles work between Anchored and Neutral panels', (
      tester,
    ) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PanelLayout(
            children: [
              InlinePanel(
                id: const PanelId('top_anchor'),
                anchor: PanelAnchor.top,
                height: 50,
                child: const SizedBox.expand(),
              ),
              InlinePanel(
                id: const PanelId('resize_neutral'),
                height: 100,
                child: const SizedBox.expand(),
              ),
            ],
          ),
        ),
      );

      expect(find.byType(PanelResizeHandle), findsOneWidget);

      // Drag it down
      await tester.drag(find.byType(PanelResizeHandle), const Offset(0, 20));
      await tester.pump();

      // Top panel should now be 70
      final topFinder = find.byWidgetPredicate(
        (w) =>
            w is PanelDataScope && w.config.id == const PanelId('top_anchor'),
      );
      final topRect = tester.getRect(topFinder);
      expect(topRect.height, 70);
    });
  });

  group('Nested Mixed Axis', () {
    testWidgets('Nested layouts with mixed axes do not crash', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PanelLayout(
            children: [
              InlinePanel(
                id: const PanelId('root_top'),
                anchor: PanelAnchor.top,
                height: 50,
                child: const Text('Root Top'),
              ),
              TestContentPanel(
                id: const PanelId('inner_container'),
                layoutWeightOverride: 1,
                child: PanelLayout(
                  children: [
                    InlinePanel(
                      id: const PanelId('inner_left'),
                      anchor: PanelAnchor.left,
                      width: 100,
                      child: const Text('Inner Left'),
                    ),
                    TestContentPanel(
                      id: const PanelId('inner_neutral'),
                      layoutWeightOverride: 1,
                      child: const Text('Inner Neutral'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Root Top'), findsOneWidget);
      expect(find.text('Inner Left'), findsOneWidget);
      expect(find.text('Inner Neutral'), findsOneWidget);
    });
  });
}
