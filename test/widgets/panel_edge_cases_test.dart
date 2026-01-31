import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_panels/flutter_panels.dart';
import 'package:flutter_panels/src/widgets/internal/panel_resize_handle.dart';

void main() {
  group('Edge Cases', () {
    testWidgets('Empty PanelArea works', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: PanelArea(children: []),
        ),
      );
      expect(find.byType(PanelArea), findsOneWidget);
    });

    testWidgets('Duplicate IDs (Last one wins)', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PanelArea(
            children: [
              InlinePanel(
                id: const PanelId('dup'),
                width: 100,
                child: const Text('First'),
              ),
              InlinePanel(
                id: const PanelId('dup'),
                width: 200,
                child: const Text('Second'),
              ),
            ],
          ),
        ),
      );

      expect(find.text('First'), findsNothing);
      expect(find.text('Second'), findsOneWidget);
    });

    testWidgets('Handle disappears when panel is hidden', (tester) async {
      final controller = PanelAreaController();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PanelArea(
            controller: controller,
            children: [
              InlinePanel(
                id: const PanelId('p1'),
                width: 100,
                child: Container(),
              ),
              InlinePanel(
                id: const PanelId('p2'),
                width: 100,
                child: Container(),
              ),
            ],
          ),
        ),
      );

      expect(find.byType(PanelResizeHandle), findsOneWidget);

      controller.setVisible(const PanelId('p1'), false);
      await tester.pumpAndSettle();

      expect(find.byType(PanelResizeHandle), findsNothing);
    });
  });
}
