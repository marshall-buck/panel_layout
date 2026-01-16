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
              collapsedChild: PanelToggleButton(key: Key('strip'), icon: SizedBox()),
              child: Container(key: const Key('content')),
            ),
          ],
        ),
      ),
    );

    expect(tester.getSize(find.byType(LayoutId)).width, 200.0);
    expect(find.byKey(const Key('content')), findsOneWidget);
    expect(find.byKey(const Key('strip')), findsOneWidget);

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
              child: const PanelToggleButton(icon: Text('Icon')),
            ),
          ],
        ),
      ),
    );

    final transformFinder = find.descendant(
      of: find.byType(PanelToggleButton),
      matching: find.byType(Transform),
    );

    Transform transform = tester.widget(transformFinder);
    Matrix4 matrix = transform.transform;
    double angle = math.atan2(matrix.entry(1, 0), matrix.entry(0, 0));
    expect(angle, 0.0);

    final controller = PanelLayout.of(
      tester.element(find.byType(PanelToggleButton)),
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
              collapsedChild: PanelToggleButton(
                icon: SizedBox(),
                decoration: BoxDecoration(color: Color(0xFFFF0000)),
              ),
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
              collapsedChild: PanelToggleButton(
                key: Key('strip'),
                icon: SizedBox(),
                decoration: BoxDecoration(color: Color(0xFFFF0000)),
              ),
              child: Container(
                key: const Key('content'),
                color: const Color(0xFF00FF00),
              ),
            ),
          ],
        ),
      ),
    );

    expect(tester.getTopLeft(find.byKey(const Key('strip'))).dy, 0.0);
    expect(tester.getSize(find.byKey(const Key('strip'))).height, 40.0);
    expect(tester.getTopLeft(find.byKey(const Key('content'))).dy, 0.0);
    expect(tester.getSize(find.byKey(const Key('content'))).height, 200.0);

    final controller = PanelLayout.of(
      tester.element(find.byKey(const Key('content'))),
    );
    controller.setCollapsed(id, true);

    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(LayoutId)).height, 40.0);
    expect(tester.getTopLeft(find.byKey(const Key('strip'))).dy, 0.0);
    expect(tester.getTopLeft(find.byKey(const Key('content'))).dy, 0.0);
  });
}
