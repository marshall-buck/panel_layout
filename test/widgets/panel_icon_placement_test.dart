import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/panel_layout.dart';
import 'package:panel_layout/src/widgets/internal/panel_toggle_button.dart';

void main() {
  Widget buildTestLayout(List<BasePanel> children) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 800,
          height: 600,
          child: PanelLayout(children: children),
        ),
      ),
    );
  }

  testWidgets('Icon is on RIGHT for Right-anchored panel (Closes Right)', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestLayout([
        InlinePanel(
          id: const PanelId('right_panel'),
          anchor: PanelAnchor.right,
          width: 200,
          title: 'Title',
          icon: const Icon(Icons.chevron_left),
          child: const SizedBox(),
        ),
      ]),
    );

    // Find the header Row
    final headerFinder = find.byKey(const Key('panel_header_right_panel'));
    expect(headerFinder, findsOneWidget);

    final row = tester.widget<Row>(
      find.descendant(of: headerFinder, matching: find.byType(Row)),
    );

    // Check children order: ToggleButton should be last
    expect(row.children.length, greaterThanOrEqualTo(2));
    expect(row.children.last, isA<PanelToggleButton>());

    // Verify Text is before
    final textFinder = find.descendant(
      of: headerFinder,
      matching: find.text('Title'),
    );
    expect(textFinder, findsOneWidget);

    final iconFinder = find.descendant(
      of: headerFinder,
      matching: find.byType(PanelToggleButton),
    );

    // Verify visual position
    final iconCenter = tester.getCenter(iconFinder);
    final textCenter = tester.getCenter(textFinder);

    expect(
      iconCenter.dx,
      greaterThan(textCenter.dx),
      reason: "Icon should be to the right of Text",
    );
  });

  testWidgets('Icon is on LEFT for Left-anchored panel (Closes Left)', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestLayout([
        InlinePanel(
          id: const PanelId('left_panel'),
          anchor: PanelAnchor.left,
          width: 200,
          title: 'Title',
          icon: const Icon(Icons.chevron_left),
          child: const SizedBox(),
        ),
      ]),
    );

    final headerFinder = find.byKey(const Key('panel_header_left_panel'));

    final textFinder = find.descendant(
      of: headerFinder,
      matching: find.text('Title'),
    );
    final iconFinder = find.descendant(
      of: headerFinder,
      matching: find.byType(PanelToggleButton),
    );

    final iconCenter = tester.getCenter(iconFinder);
    final textCenter = tester.getCenter(textFinder);

    expect(
      iconCenter.dx,
      lessThan(textCenter.dx),
      reason: "Icon should be to the left of Text",
    );
  });

  testWidgets('Icon is on RIGHT for Top-anchored panel', (tester) async {
    await tester.pumpWidget(
      buildTestLayout([
        InlinePanel(
          id: const PanelId('top_panel'),
          anchor: PanelAnchor.top,
          height: 100,
          title: 'Title',
          icon: const Icon(Icons.chevron_left),
          child: const SizedBox(),
        ),
      ]),
    );

    final headerFinder = find.byKey(const Key('panel_header_top_panel'));
    final textFinder = find.descendant(
      of: headerFinder,
      matching: find.text('Title'),
    );
    final iconFinder = find.descendant(
      of: headerFinder,
      matching: find.byType(PanelToggleButton),
    );

    final iconCenter = tester.getCenter(iconFinder);
    final textCenter = tester.getCenter(textFinder);

    expect(
      iconCenter.dx,
      greaterThan(textCenter.dx),
      reason: "Icon should be to the right of Text",
    );
  });

  testWidgets(
    'Icon is on LEFT for Right-anchored panel if closingDirection is overridden to Left',
    (tester) async {
      await tester.pumpWidget(
        buildTestLayout([
          InlinePanel(
            id: const PanelId('weird_panel'),
            anchor: PanelAnchor.right,
            closingDirection: PanelAnchor
                .left, // Forces "Effective Closing Direction" to Left
            width: 200,
            title: 'Title',
            icon: const Icon(Icons.chevron_left),
            child: const SizedBox(),
          ),
        ]),
      );

      // Logic: effectiveClosingDir = Left. showIconOnLeft = (effectiveClosingDir == Left) -> True.
      // So Icon should be on LEFT.

      final headerFinder = find.byKey(const Key('panel_header_weird_panel'));
      final textFinder = find.descendant(
        of: headerFinder,
        matching: find.text('Title'),
      );
      final iconFinder = find.descendant(
        of: headerFinder,
        matching: find.byType(PanelToggleButton),
      );

      final iconCenter = tester.getCenter(iconFinder);
      final textCenter = tester.getCenter(textFinder);

      expect(
        iconCenter.dx,
        lessThan(textCenter.dx),
        reason:
            "Icon should be to the left of Text because closingDirection is Left",
      );
    },
  );
}
