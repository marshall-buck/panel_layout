import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/panel_layout.dart';

void main() {
  testWidgets('Panel collapse animation respects collapsedSize', (
    tester,
  ) async {
    final id = PanelId('test');

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: PanelLayout(
          children: [
            InlinePanel(
              id: id,
              width: 200,
              collapsedSize: 50,
              initialCollapsed: false,
              toggleIcon: SizedBox(key: Key('toggle_icon')),
              child: Container(key: const Key('content')),
            ),
          ],
        ),
      ),
    );

    expect(tester.getSize(find.byType(LayoutId)).width, 200.0);
    expect(find.byKey(const Key('content')), findsOneWidget);
    expect(find.byKey(const Key('toggle_icon')), findsOneWidget);

    final controller = PanelLayout.of(
      tester.element(find.byKey(const Key('content'))),
    );
    controller.setCollapsed(id, true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final midWidth = tester.getSize(find.byType(LayoutId)).width;
    expect(midWidth, lessThan(200.0));
    expect(midWidth, greaterThan(50.0));

    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(LayoutId)).width, 50.0);
  });

  testWidgets('PanelToggleButton rotates based on anchor', (tester) async {
    final id = PanelId('test');

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: PanelLayout(
          children: [
            InlinePanel(
              id: id,
              width: 200,
              collapsedSize: 50,
              anchor: PanelAnchor.left,
              toggleIcon: const Text('Icon', key: Key('icon_text')),
              child: const SizedBox(),
            ),
          ],
        ),
      ),
    );

    // Find the Transform widget that is an ancestor of the icon text
    final transformFinder = find.ancestor(
      of: find.byKey(const Key('icon_text')),
      matching: find.byType(Transform),
    );

    expect(transformFinder, findsOneWidget);

    Transform transform = tester.widget(transformFinder);
    Matrix4 matrix = transform.transform;
    double angle = math.atan2(matrix.entry(1, 0), matrix.entry(0, 0));
    expect(angle, 0.0);

    final controller = PanelLayout.of(
      tester.element(find.byKey(const Key('icon_text'))),
    );
    controller.setCollapsed(id, true);
    await tester.pumpAndSettle();

    transform = tester.widget(transformFinder);
    matrix = transform.transform;
    angle = math.atan2(matrix.entry(1, 0), matrix.entry(0, 0));

    if (angle < 0) angle += 2 * math.pi;

    expect(angle, closeTo(math.pi, 0.001));
  });

  testWidgets('Panel content does not overflow when collapsed', (tester) async {
    final id = PanelId('overflow_test');

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: PanelLayout(
          children: [
            InlinePanel(
              id: id,
              width: 200,
              collapsedSize: 50,
              toggleIcon: SizedBox(),
              collapsedDecoration: BoxDecoration(color: Color(0xFFFF0000)),
              child: Row(
                children: [
                  SizedBox(width: 150, height: 20, child: const Text('Wide Content')),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    expect(tester.takeException(), isNull);

    final controller = PanelLayout.of(tester.element(find.byType(Row)));
    controller.setCollapsed(id, true);

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('Panel strip positioning works for Top/Bottom anchors', (
    tester,
  ) async {
    final id = PanelId('vertical_test');

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: PanelLayout(
          axis: Axis.vertical,
          children: [
            InlinePanel(
              id: id,
              height: 200,
              collapsedSize: 40,
              anchor: PanelAnchor.top,
              toggleIcon: SizedBox(key: Key('toggle_icon')),
              collapsedDecoration: BoxDecoration(color: Color(0xFFFF0000)),
              child: Container(
                key: const Key('content'),
                color: const Color(0xFF00FF00),
              ),
            ),
          ],
        ),
      ),
    );

    // We can't easily test the strip container frame since it's private in AnimatedPanel stack.
    // But we can verify the content is at 0,0 and the layout size is correct.
    expect(tester.getTopLeft(find.byKey(const Key('content'))).dy, 0.0);
    expect(tester.getSize(find.byKey(const Key('content'))).height, 200.0);

    final controller = PanelLayout.of(
      tester.element(find.byKey(const Key('content'))),
    );
    controller.setCollapsed(id, true);

    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(LayoutId)).height, 40.0);
    // Content should still be at top left in the stack, even if clipped/hidden
    expect(tester.getTopLeft(find.byKey(const Key('content'))).dy, 0.0);
    
    // Verify icon is present
    expect(find.byKey(const Key('toggle_icon')), findsOneWidget);
  });
}