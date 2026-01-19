import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/panel_layout.dart';
import 'package:panel_layout/src/widgets/panel_toggle_button.dart';

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
              toggleIconSize: 50,
              toggleIconPadding: 0,
              initialCollapsed: false,
              icon: SizedBox(key: Key('toggle_icon')),
              child: Container(key: const Key('content')),
            ),
          ],
        ),
      ),
    );

    expect(tester.getSize(find.byType(LayoutId)).width, 200.0);
    expect(find.byKey(const Key('content')), findsOneWidget);
    // Expect 2 icons: One in Header, One in Rail
    expect(find.byKey(const Key('toggle_icon')), findsNWidgets(2));

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
              toggleIconSize: 50,
              toggleIconPadding: 0,
              anchor: PanelAnchor.left,
              icon: const Text('Icon', key: Key('icon_text')),
              child: const SizedBox(),
            ),
          ],
        ),
      ),
    );

    // Target the icon in the Rail (PanelToggleButton)
    final railIconFinder = find.descendant(
      of: find.byType(PanelToggleButton),
      matching: find.byKey(const Key('icon_text')),
    );

    // Find the Transform widget that is an ancestor of the rail icon text
    final transformFinder = find.ancestor(
      of: railIconFinder,
      matching: find.byType(Transform),
    );

    // Initial state: Not collapsed, rail might be hidden or opacity 0.
    // Wait, if not collapsed, the rail is not rendered?
    // AnimatedPanel logic:
    // child: Stack(children: [childWidget, if (stripWidget != null) Positioned(...)])
    // Positioned child: IgnorePointer(ignoring: collapseFactor == 0.0, child: Opacity(...))
    // So it IS in the tree.

    expect(transformFinder, findsOneWidget);

    Transform transform = tester.widget(transformFinder);
    Matrix4 matrix = transform.transform;
    double angle = math.atan2(matrix.entry(1, 0), matrix.entry(0, 0));
    expect(angle, 0.0);

    final controller = PanelLayout.of(
      tester.element(railIconFinder),
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
              toggleIconSize: 50,
              toggleIconPadding: 0,
              icon: SizedBox(),
              railDecoration: BoxDecoration(color: Color(0xFFFF0000)),
              child: Row(
                children: [
                  SizedBox(
                    width: 150,
                    height: 20,
                    child: const Text('Wide Content'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    expect(tester.takeException(), isNull);

    final contentRowFinder = find.ancestor(
      of: find.text('Wide Content'),
      matching: find.byType(Row),
    );

    final controller = PanelLayout.of(tester.element(contentRowFinder));
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
              toggleIconSize: 40,
              toggleIconPadding: 0,
              anchor: PanelAnchor.top,
              icon: SizedBox(key: Key('toggle_icon')),
              railDecoration: BoxDecoration(color: Color(0xFFFF0000)),
              child: Container(
                key: const Key('content'),
                color: const Color(0xFF00FF00),
              ),
            ),
          ],
        ),
      ),
    );

    // Header (32.0) pushes content down.
    expect(tester.getTopLeft(find.byKey(const Key('content'))).dy, 32.0);
    // Height is panel height (200) - header height (32) ?
    // No, BasePanel is a Column [Header, Expanded(child)].
    // So child height = 200 - 32 = 168.
    expect(tester.getSize(find.byKey(const Key('content'))).height, 200.0 - 32.0);

    final controller = PanelLayout.of(
      tester.element(find.byKey(const Key('content'))),
    );
    controller.setCollapsed(id, true);

    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(LayoutId)).height, 40.0);
    // Content should still be at top (offset by header)
    expect(tester.getTopLeft(find.byKey(const Key('content'))).dy, 32.0);

    // Verify icon is present (2 of them)
    expect(find.byKey(const Key('toggle_icon')), findsNWidgets(2));
  });
}
