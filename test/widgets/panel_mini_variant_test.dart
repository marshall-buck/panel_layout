import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_panels/flutter_panels.dart';
import 'package:flutter_panels/src/widgets/internal/panel_toggle_button.dart';
import 'package:flutter_panels/src/core/constants.dart';

void main() {
  testWidgets('Panel collapse animation respects collapsedSize', (
    tester,
  ) async {
    final id = PanelId('test');
    const testIconSize = 34.0;
    const expectedCollapsedSize =
        testIconSize + kDefaultRailPadding; // 34 + 16 = 50

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: PanelArea(
          children: [
            InlinePanel(
              id: id,
              width: 200,
              iconSize: testIconSize,
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

    final controller = PanelArea.of(
      tester.element(find.byKey(const Key('content'))),
    );
    controller.setCollapsed(id, true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final midWidth = tester.getSize(find.byType(LayoutId)).width;
    expect(midWidth, lessThan(200.0));
    expect(midWidth, greaterThan(expectedCollapsedSize));

    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(LayoutId)).width, expectedCollapsedSize);
  });

  testWidgets('PanelToggleButton rotates based on anchor', (tester) async {
    final id = PanelId('test');

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: PanelArea(
          children: [
            InlinePanel(
              id: id,
              width: 200,
              iconSize: 50,
              anchor: PanelAnchor.left,
              icon: const Text('Icon', key: Key('icon_text')),
              child: const SizedBox(),
            ),
          ],
        ),
      ),
    );

    // Target the icon in the Rail (PanelToggleButton)
    // The rail is rendered inside a Positioned widget within AnimatedPanel
    final railIconFinder = find.descendant(
      of: find.descendant(
        of: find.byType(Positioned),
        matching: find.byType(PanelToggleButton),
      ),
      matching: find.byKey(const Key('icon_text')),
    );

    // Find the Transform widget that is an ancestor of the rail icon text
    // There is only one Transform inside PanelToggleButton
    final transformFinder = find
        .ancestor(of: railIconFinder, matching: find.byType(Transform))
        .first;

    expect(transformFinder, findsOneWidget);

    Transform transform = tester.widget(transformFinder);
    Matrix4 matrix = transform.transform;
    double angle = math.atan2(matrix.entry(1, 0), matrix.entry(0, 0));
    expect(angle, 0.0);

    final controller = PanelArea.of(tester.element(railIconFinder));
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
        child: PanelArea(
          children: [
            InlinePanel(
              id: id,
              width: 200,
              iconSize: 50,
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

    final controller = PanelArea.of(tester.element(contentRowFinder));
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
    const testIconSize = 24.0;
    const expectedCollapsedSize =
        testIconSize + kDefaultRailPadding; // 24 + 16 = 40
    const expectedHeaderHeight = testIconSize + (kDefaultHeaderPadding * 2);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: PanelArea(
          children: [
            InlinePanel(
              id: id,
              height: 200,
              iconSize: testIconSize,
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

    // Header (expectedHeaderHeight) pushes content down.
    expect(
      tester.getTopLeft(find.byKey(const Key('content'))).dy,
      expectedHeaderHeight,
    );
    // Height is panel height (200) - header height (expectedHeaderHeight)
    // BasePanel is a Column [Header, Expanded(child)].
    expect(
      tester.getSize(find.byKey(const Key('content'))).height,
      200.0 - expectedHeaderHeight,
    );

    final controller = PanelArea.of(
      tester.element(find.byKey(const Key('content'))),
    );
    controller.setCollapsed(id, true);

    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(LayoutId)).height, expectedCollapsedSize);
    // Content should still be at top (offset by header)
    expect(
      tester.getTopLeft(find.byKey(const Key('content'))).dy,
      expectedHeaderHeight,
    );

    // Verify icon is present (1 of them, since we reuse the header)
    expect(find.byKey(const Key('toggle_icon')), findsOneWidget);
  });
}
