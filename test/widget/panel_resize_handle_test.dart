import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/src/panel_resize_handle.dart';
import 'package:panel_layout/src/panel_theme.dart';

void main() {
  group('PanelResizeHandle', () {
    testWidgets('renders correctly', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PanelResizeHandle(onDragUpdate: (_) {}),
        ),
      );

      expect(find.byType(PanelResizeHandle), findsOneWidget);
      expect(find.byType(MouseRegion), findsOneWidget);
      expect(find.byType(GestureDetector), findsOneWidget);
    });

    testWidgets('shows correct cursor', (tester) async {
      // Vertical (default)
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PanelResizeHandle(onDragUpdate: (_) {}),
        ),
      );
      expect(
        tester.widget<MouseRegion>(find.byType(MouseRegion)).cursor,
        SystemMouseCursors.resizeColumn,
      );

      // Horizontal
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PanelResizeHandle(
            axis: Axis.horizontal,
            onDragUpdate: (_) {},
          ),
        ),
      );
      expect(
        tester.widget<MouseRegion>(find.byType(MouseRegion)).cursor,
        SystemMouseCursors.resizeRow,
      );
    });

    testWidgets('calls onDragUpdate with correct delta', (tester) async {
      double lastDelta = 0;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PanelResizeHandle(
            onDragUpdate: (delta) => lastDelta = delta,
          ),
        ),
      );

      // Drag right
      await tester.drag(find.byType(PanelResizeHandle), const Offset(10, 0));
      expect(lastDelta, 10.0);

      // Drag left
      await tester.drag(find.byType(PanelResizeHandle), const Offset(-5, 0));
      expect(lastDelta, -5.0);
    });

    testWidgets('calls onDragStart/End', (tester) async {
      bool started = false;
      bool ended = false;
      
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PanelResizeHandle(
            onDragUpdate: (_) {},
            onDragStart: () => started = true,
            onDragEnd: () => ended = true,
          ),
        ),
      );

      final gesture = await tester.startGesture(tester.getCenter(find.byType(PanelResizeHandle)));
      expect(started, true);
      
      await gesture.moveBy(const Offset(10, 0));
      await gesture.up();
      expect(ended, true);
    });

    testWidgets('responds to hover state visually', (tester) async {
      // We can verify that state changes, though testing exact color rendering via widget test 
      // usually involves checking the Container decoration.
      
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PanelTheme(
            data: const PanelThemeData(
              resizeHandleColor: Color(0xFF000000),
              resizeHandleHoverColor: Color(0xFF00FF00),
            ),
            child: PanelResizeHandle(onDragUpdate: (_) {}),
          ),
        ),
      );

      // Initial state: not hovered
      final handleFinder = find.byType(AnimatedContainer);
      BoxDecoration decoration = tester.widget<AnimatedContainer>(handleFinder).decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFF000000));

      // Simulate hover
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.byType(PanelResizeHandle)));
      await tester.pumpAndSettle();

      decoration = tester.widget<AnimatedContainer>(handleFinder).decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFF00FF00));
    });
  });
}
