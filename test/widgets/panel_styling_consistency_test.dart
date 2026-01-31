import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_panels/flutter_panels.dart';
import 'package:flutter_panels/src/widgets/internal/panel_toggle_button.dart';
import '../utils/test_content_panel.dart';

void main() {
  testWidgets('Panel styling consistency between Expanded and Collapsed states', (
    tester,
  ) async {
    final controller = PanelAreaController();
    const panelId = PanelId('test_panel');
    const testIconColor = Colors.red;
    const testHeaderColor = Colors.blue;

    await tester.pumpWidget(
      MaterialApp(
        home: PanelArea(
          controller: controller,
          style: const PanelStyle(
            headerDecoration: BoxDecoration(color: Colors.white), // Default
          ),
          children: [
            InlinePanel(
              id: panelId,
              anchor: PanelAnchor.left,
              width: 200,
              // Custom styling that should persist
              icon: const Icon(Icons.chevron_left),
              iconColor: testIconColor,
              headerDecoration: const BoxDecoration(color: testHeaderColor),
              child: const Text('Content'),
            ),
            const TestContentPanel(
              id: PanelId('main'),
              layoutWeightOverride: 1,
              child: Text('Main'),
            ),
          ],
        ),
      ),
    );

    // 1. Verify Expanded State (Header)
    expect(find.text('Content'), findsOneWidget);

    // Check Header Background Color
    // The header container is the first child of the Column in BasePanel
    final headerContainerFinder = find
        .descendant(of: find.byType(Column), matching: find.byType(Container))
        .first;

    final headerContainer = tester.widget<Container>(headerContainerFinder);
    final headerDecoration = headerContainer.decoration as BoxDecoration;
    expect(
      headerDecoration.color,
      testHeaderColor,
      reason: 'Header should use custom headerDecoration',
    );

    // Check Header Icon Color
    // The header uses PanelToggleButton. We need to find the one inside the header row.
    final headerToggleButtonFinder = find.descendant(
      of: headerContainerFinder,
      matching: find.byType(PanelToggleButton),
    );

    // PanelToggleButton uses an internal IconTheme.
    final iconTheme = tester.widget<IconTheme>(
      find.descendant(
        of: headerToggleButtonFinder,
        matching: find.byType(IconTheme),
      ),
    );
    expect(
      iconTheme.data.color,
      testIconColor,
      reason: 'Header icon should use custom iconColor',
    );

    // 2. Collapse the Panel
    controller.toggleCollapsed(panelId);
    await tester.pump(); // Start animation
    await tester.pump(const Duration(milliseconds: 500)); // End animation

    // 3. Verify Collapsed State (Rail)
    // Content should be hidden via Opacity
    final contentOpacityFinder = find
        .ancestor(of: find.text('Content'), matching: find.byType(Opacity))
        .first;
    final contentOpacity = tester.widget<Opacity>(contentOpacityFinder);
    expect(
      contentOpacity.opacity,
      0.0,
      reason: 'Content should be invisible (opacity 0)',
    );

    // Find the Rail Container (AnimatedPanel renders it in a Stack)
    // It is inside a Positioned widget.
    final railContainerFinder = find.descendant(
      of: find.byType(Positioned),
      matching: find.byType(Container),
    );

    // There might be multiple Positioned/Containers (e.g. scrollbars?), so be specific.
    // The rail container contains the PanelToggleButton.
    final railToggleButtonFinder = find.descendant(
      of: railContainerFinder,
      matching: find.byType(PanelToggleButton),
    );

    // Ensure we found the rail toggle button
    expect(railToggleButtonFinder, findsOneWidget);

    final railContainer = tester.widget<Container>(
      find
          .ancestor(
            of: railToggleButtonFinder,
            matching: find.byType(Container),
          )
          .first,
    );

    // Check Rail Background Color (Should match Header Color)
    final railDecoration = railContainer.decoration as BoxDecoration?;
    expect(
      railDecoration?.color,
      testHeaderColor,
      reason:
          'Rail should inherit custom headerDecoration if railDecoration is null',
    );

    // Check Rail Icon Color (Should match Header Icon Color)
    final railIconTheme = tester.widget<IconTheme>(
      find.descendant(
        of: railToggleButtonFinder,
        matching: find.byType(IconTheme),
      ),
    );
    expect(
      railIconTheme.data.color,
      testIconColor,
      reason: 'Rail icon should inherit custom iconColor',
    );

    // 4. Verify Rotation
    // In collapsed state, rotation should be non-zero (pi for Left anchor)
    final transform = tester.widget<Transform>(
      find.descendant(
        of: railToggleButtonFinder,
        matching: find.byType(Transform),
      ),
    );
    final matrix = transform.transform;
    // Check if rotated (simplistic check for non-identity)
    expect(matrix.isIdentity(), isFalse, reason: 'Rail icon should be rotated');
  });
}
