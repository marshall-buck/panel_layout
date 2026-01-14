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
}
