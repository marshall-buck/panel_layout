import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/panel_layout.dart';

class SimplePanel extends BasePanel {
  SimplePanel({
    super.key,
    required String id,
    super.width,
    super.flex,
    required super.child,
  }) : super(id: PanelId(id));
}

void main() {
  group('Edge Cases', () {
    testWidgets('Empty PanelLayout works', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: PanelLayout(children: []),
        ),
      );
      expect(find.byType(PanelLayout), findsOneWidget);
    });

    testWidgets('Duplicate IDs (Last one wins)', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PanelLayout(
            children: [
              SimplePanel(id: 'dup', width: 100, child: const Text('First')),
              SimplePanel(id: 'dup', width: 200, child: const Text('Second')),
            ],
          ),
        ),
      );

      expect(find.text('First'), findsNothing);
      expect(find.text('Second'), findsOneWidget);
    });

    testWidgets('Handle disappears when panel is hidden', (tester) async {
      final controller = PanelLayoutController();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PanelLayout(
            controller: controller,
            children: [
              SimplePanel(id: 'p1', width: 100, child: Container()),
              SimplePanel(id: 'p2', width: 100, child: Container()),
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
