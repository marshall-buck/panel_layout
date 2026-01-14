import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/panel_layout.dart';

class TestPanel extends BasePanel {
  const TestPanel({
    required super.id,
    required super.child,
    super.collapsedChild,
    super.collapsedSize,
    super.width,
    super.height,
    super.initialCollapsed,
    super.anchor,
    super.key,
  });
}

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
            TestPanel(
              id: id,
              width: 200,
              collapsedSize: 50,
              initialCollapsed: false,
              collapsedChild: Container(key: Key('strip')),
              child: Container(key: Key('content')),
            ),
          ],
        ),
      ),
    );

    // Initial state: 200px width.
    expect(tester.getSize(find.byType(LayoutId)).width, 200.0);
    expect(find.byKey(Key('content')), findsOneWidget);
    // Strip is in the stack, but might be obscured or visible depending on impl.
    // In our Stack impl, both are present.
    expect(find.byKey(Key('strip')), findsOneWidget);

    // Toggle collapse
    // Toggle collapse
    final controller = PanelLayout.of(
      tester.element(find.byKey(Key('content'))),
    );
    controller.setCollapsed(id, true);
    await tester.pump(); // Start animation
    await tester.pump(const Duration(milliseconds: 100)); // Partial

    // Should be shrinking
    final midWidth = tester.getSize(find.byType(LayoutId)).width;
    expect(midWidth, lessThan(200.0));
    expect(midWidth, greaterThan(50.0));

    await tester.pumpAndSettle();

    // Final state: 50px width
    expect(tester.getSize(find.byType(LayoutId)).width, 50.0);
  });

  testWidgets('PanelToggleButton rotates based on anchor', (tester) async {
    final id = PanelId('test');

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: PanelLayout(
          children: [
            TestPanel(
              id: id,
              width: 200,
              collapsedSize: 50,
              anchor: PanelAnchor.left,
              child: PanelToggleButton(child: Text('Icon')),
            ),
          ],
        ),
      ),
    );

    final transformFinder = find.descendant(
      of: find.byType(PanelToggleButton),
      matching: find.byType(Transform),
    );

    // Anchor Left + Expanded -> Rotation 0
    Transform transform = tester.widget(transformFinder);
    Matrix4 matrix = transform.transform;
    // Calculate Z rotation: atan2(sin, cos) -> atan2(entry(1,0), entry(0,0))
    double angle = math.atan2(matrix.entry(1, 0), matrix.entry(0, 0));
    expect(angle, 0.0); // No rotation

    // Collapse
    final controller = PanelLayout.of(
      tester.element(find.byType(PanelToggleButton)),
    );
    controller.setCollapsed(id, true);
    await tester.pumpAndSettle();

    // Anchor Left + Collapsed -> Rotation Pi (180 deg)
    transform = tester.widget(transformFinder);
    matrix = transform.transform;
    angle = math.atan2(matrix.entry(1, 0), matrix.entry(0, 0));

    // Normalize angle to 0..pi
    if (angle < 0) angle += 2 * math.pi;

    expect(angle, closeTo(math.pi, 0.001));
  });

  testWidgets('Panel content does not overflow when collapsed', (tester) async {
    // Regression test for issue where main content was constrained to collapsedSize,

    // causing overflow errors for Row/Flex widgets.

    final id = PanelId('overflow_test');

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,

        child: PanelLayout(
          children: [
            TestPanel(
              id: id,

              width: 200,

              collapsedSize: 50,

              collapsedChild: Container(
                width: 50,
                color: const Color(0xFFFF0000),
              ),

              // Content requires at least 150px width, or it overflows
              child: Row(
                children: [
                  SizedBox(width: 150, height: 20, child: Text('Wide Content')),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    // Initial check - Expanded (200px) > Content (150px)

    expect(tester.takeException(), isNull);

    // Toggle collapse

    final controller = PanelLayout.of(tester.element(find.byType(Row)));

    controller.setCollapsed(id, true);

    // Animate through the collapse

    await tester.pump();

    await tester.pump(const Duration(milliseconds: 100));

    // Check for exceptions during animation

    expect(tester.takeException(), isNull);

    await tester.pumpAndSettle();

    // Final check - Collapsed (50px) < Content (150px)

    // Should NOT throw if OverflowBox is working correctly.

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
            TestPanel(
              id: id,

              height: 200,

              collapsedSize: 40,

              anchor: PanelAnchor.top,

              collapsedChild: Container(
                key: Key('strip'),
                color: const Color(0xFFFF0000),
              ),

              // Content needs to be distinct
              child: Container(
                key: Key('content'),
                color: const Color(0xFF00FF00),
              ),
            ),
          ],
        ),
      ),
    );

    // Initial State: Expanded (200px)

    // Strip should be at top (0,0), Content also at (0,0) (Overlapping/Stacked)
    expect(tester.getTopLeft(find.byKey(Key('strip'))).dy, 0.0);
    expect(tester.getSize(find.byKey(Key('strip'))).height, 40.0);

    expect(tester.getTopLeft(find.byKey(Key('content'))).dy, 0.0);

    // Content height = Expanded (200)
    expect(tester.getSize(find.byKey(Key('content'))).height, 200.0);

    // Toggle Collapse

    final controller = PanelLayout.of(
      tester.element(find.byKey(Key('content'))),
    );

    controller.setCollapsed(id, true);

    await tester.pumpAndSettle();

    // Collapsed State: Total Height 40px

    // Strip (40px) takes full height. Content (200px) is clipped.

    // Parent AnimatedPanel clips at 40px.

    expect(tester.getSize(find.byType(LayoutId)).height, 40.0);

    // Strip is still at 0

    expect(tester.getTopLeft(find.byKey(Key('strip'))).dy, 0.0);

    // Content is still at 0 (effectively hidden/clipped out of view)

    expect(tester.getTopLeft(find.byKey(Key('content'))).dy, 0.0);
  });
}
