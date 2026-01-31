import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_panels/flutter_panels.dart';
import 'package:flutter_panels/src/widgets/internal/panel_toggle_button.dart';

void main() {
  Widget buildTestWidget({
    required PanelAnchor anchor,
    required bool collapsed,
  }) {
    // We mock the environment by manually providing the data needed for PanelToggleButton.
    // However, PanelToggleButton uses PanelScope and PanelDataScope.
    // It's easier to build a minimal PanelArea.
    return MaterialApp(
      home: Scaffold(
        body: PanelArea(
          controller: PanelAreaController(), // Unused, we set initial state
          children: [
            InlinePanel(
              id: const PanelId('test_panel'),
              anchor: anchor,
              initialCollapsed: collapsed,
              height: 100,
              width: 100,
              icon: const Icon(Icons.chevron_left),
              child: const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  testWidgets('Top Panel Rotation (Closes Up)', (tester) async {
    // 1. Open State (Should point Up ^ to close)
    await tester.pumpWidget(
      buildTestWidget(anchor: PanelAnchor.top, collapsed: false),
    );
    final transformOpen = tester.widget<Transform>(
      find
          .descendant(
            of: find.byType(PanelToggleButton),
            matching: find.byType(Transform),
          )
          .first,
    );
    final matrixOpen = transformOpen.transform;
    // Rotation Z should be pi/2 (1.57)
    // Checking Matrix4 value at index 0 (cos) and 1 (sin)
    // Rot Z(90) -> [0 -1 0 0]
    //              [1  0 0 0]
    expect(matrixOpen.storage[0], closeTo(0.0, 0.001));
    // 2. Collapsed State (Should point Down v to open)
    await tester.pumpWidget(
      buildTestWidget(anchor: PanelAnchor.top, collapsed: true),
    );
    // Hack: Force state reset by using a new key or ID, but here we just need to ensure the widget tree is fresh.
    // Actually, simply disposing the previous widget by pumping a Container first would work,
    // but changing the ID is easier in the builder if I parameterized it.
    // Let's just create a new widget layout with a different ID.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PanelArea(
            controller: PanelAreaController(),

            children: [
              InlinePanel(
                id: const PanelId('test_panel_collapsed'),
                anchor: PanelAnchor.top,
                initialCollapsed: true,
                height: 100,
                width: 100,
                icon: const Icon(Icons.chevron_left),
                child: const SizedBox(),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final transformCollapsed = tester.widget<Transform>(
      find
          .descendant(
            of: find.byType(PanelToggleButton),
            matching: find.byType(Transform),
          )
          .first,
    );
    final matrixCollapsed = transformCollapsed.transform;
    // Rotation Z should be -pi/2 (-1.57)
    // Rot Z(-90) -> [0  1 0 0]
    //               [-1 0 0 0]
    expect(matrixCollapsed.storage[0], closeTo(0.0, 0.001));
    expect(matrixCollapsed.storage[1], closeTo(-1.0, 0.001)); // sin(-90) = -1
  });

  testWidgets('Bottom Panel Rotation (Closes Down)', (tester) async {
    // 1. Open State (Should point Down v to close)
    await tester.pumpWidget(
      buildTestWidget(anchor: PanelAnchor.bottom, collapsed: false),
    );
    await tester.pumpAndSettle();

    final transformOpen = tester.widget<Transform>(
      find
          .descendant(
            of: find.byType(PanelToggleButton),
            matching: find.byType(Transform),
          )
          .first,
    );
    final matrixOpen = transformOpen.transform;
    // Rot -90
    expect(matrixOpen.storage[1], closeTo(-1.0, 0.001));

    // 2. Collapsed State (Should point Up ^ to open)
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PanelArea(
            controller: PanelAreaController(),

            children: [
              InlinePanel(
                id: const PanelId('test_panel_bottom_collapsed'),
                anchor: PanelAnchor.bottom,
                initialCollapsed: true,
                height: 100,
                width: 100,
                icon: const Icon(Icons.chevron_left),
                child: const SizedBox(),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final transformCollapsed = tester.widget<Transform>(
      find
          .descendant(
            of: find.byType(PanelToggleButton),
            matching: find.byType(Transform),
          )
          .first,
    );
    final matrixCollapsed = transformCollapsed.transform;
    // Rot 90
    expect(matrixCollapsed.storage[1], closeTo(1.0, 0.001));
  });
}
