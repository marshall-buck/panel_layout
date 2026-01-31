import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_panels/flutter_panels.dart';
import 'package:flutter_panels/src/widgets/internal/panel_resize_handle.dart';
import 'package:flutter_panels/src/widgets/internal/internal_layout_adapter.dart';

void main() {
  group('Standard Widget Support', () {
    testWidgets('Wraps standard widgets in InternalLayoutAdapter', (
      tester,
    ) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 800,
            height: 600,
            child: PanelArea(
              children: [
                Container(key: const Key('child1'), color: Colors.red),
                Container(key: const Key('child2'), color: Colors.blue),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify widgets are rendered
      expect(find.byKey(const Key('child1')), findsOneWidget);
      expect(find.byKey(const Key('child2')), findsOneWidget);

      // Verify they are wrapped in InternalLayoutAdapter
      // (InternalLayoutAdapter renders child directly, so we look for ancestors)
      expect(
        find.ancestor(
          of: find.byKey(const Key('child1')),
          matching: find.byType(InternalLayoutAdapter),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Standard widgets share space equally (Flex 1.0)', (
      tester,
    ) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 800,
            height: 600,
            child: PanelArea(
              children: [
                Container(key: const Key('child1'), color: Colors.red),
                Container(key: const Key('child2'), color: Colors.blue),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final size1 = tester.getSize(find.byKey(const Key('child1')));
      final size2 = tester.getSize(find.byKey(const Key('child2')));

      // 800 width / 2 = 400 each
      expect(size1.width, equals(400.0));
      expect(size2.width, equals(400.0));
    });

    testWidgets('No resize handles between standard widgets', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 800,
            height: 600,
            child: PanelArea(
              children: [
                Container(key: const Key('child1')),
                Container(key: const Key('child2')),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(PanelResizeHandle), findsNothing);
    });

    testWidgets('Resize handle between InlinePanel and Standard Widget', (
      tester,
    ) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 800,
            height: 600,
            child: PanelArea(
              children: [
                InlinePanel(
                  id: const PanelId('sidebar'),
                  width: 200,
                  child: Container(),
                ),
                Container(key: const Key('content')),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(PanelResizeHandle), findsOneWidget);

      final contentSize = tester.getSize(find.byKey(const Key('content')));
      // 800 - 200 - 8 (handle) = 592
      expect(contentSize.width, 592.0);
    });
  });
}
