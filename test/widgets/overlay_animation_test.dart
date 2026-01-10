import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/panel_layout.dart';

void main() {
  const panelA = PanelId('panelA');
  const panelB = PanelId('panelB');

  group('Overlay Animation Direction', () {
    testWidgets('Global Left Anchor slides from Left (-1, 0)', (tester) async {
      final controller = PanelLayoutController();
      controller.registerPanel(
        panelA,
        builder: (context, _) => SizedBox(width: 100, height: 100),
        sizing: const FixedSizing(100),
        mode: PanelMode.overlay,
        anchor: PanelAnchor.left,
        isVisible: false,
        visuals: const PanelVisuals(animationDuration: Duration(seconds: 1)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PanelScope(
            controller: controller,
            child: PanelArea(
              panelLayoutController: controller,
              panelIds: const [panelA],
            ),
          ),
        ),
      );

      // Show panel
      controller.getPanel(panelA)!.setVisible(visible: true);
      await tester.pump(); // Start animation
      await tester.pump(const Duration(milliseconds: 10)); // Advance slightly

      // Find the SlideTransition wrapping the visible content
      final contentKey = ValueKey('panel_${panelA.value}_visible');
      final slideFinder = find.ancestor(
        of: find.byKey(contentKey),
        matching: find.byType(SlideTransition),
      );

      final slideTransition = tester.firstWidget<SlideTransition>(slideFinder);
      final offset = slideTransition.position.value;

      // Expect to be close to (-1, 0) moving towards (0, 0)
      expect(offset.dx, lessThan(0));
      expect(offset.dx, greaterThan(-1.1));
    });

    testWidgets('Relative Left Anchor (to Target) slides from Right (+1, 0)', (
      tester,
    ) async {
      final controller = PanelLayoutController();

      // Target
      controller.registerPanel(
        panelA,
        builder: (context, _) => SizedBox(width: 100, height: 100),
        sizing: const FixedSizing(100),
        mode: PanelMode.inline,
        anchor: PanelAnchor.right,
      );

      // Overlay anchored to Target (Left of Target)
      controller.registerPanel(
        panelB,
        builder: (context, _) => SizedBox(width: 100, height: 100),
        sizing: const FixedSizing(100),
        mode: PanelMode.overlay,
        anchor: PanelAnchor.left,
        anchorPanel: panelA,
        isVisible: false,
        visuals: const PanelVisuals(animationDuration: Duration(seconds: 1)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PanelScope(
            controller: controller,
            child: PanelArea(
              panelLayoutController: controller,
              panelIds: const [panelA, panelB],
            ),
          ),
        ),
      );

      // Show panel
      controller.getPanel(panelB)!.setVisible(visible: true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));

      final contentKey = ValueKey('panel_${panelB.value}_visible');
      final slideFinder = find.ancestor(
        of: find.byKey(contentKey),
        matching: find.byType(SlideTransition),
      );

      final slideTransition = tester.firstWidget<SlideTransition>(slideFinder);
      final offset = slideTransition.position.value;

      // CURRENT BEHAVIOR (BUG): Starts at -1 (Left).
      // EXPECTED BEHAVIOR: Start at +1 (Right) because it's anchored Left of Target, so it slides out from Target (Right).

      expect(offset.dx, greaterThan(0));
    });

    // TODO: Fix this test case. Currently fails because hidden panels (size 0) lose their
    // geometry, causing anchored overlays to fall back to global positioning.
    /*
    testWidgets(
      'Overlay anchored to HIDDEN inline panel is positioned correctly',
      (tester) async {
        // Reproducing OilNet scenario:
        // SettingsPanel (Inline, Right, Hidden -> 0 width at Right Edge)
        // SettingsChangePanel (Overlay, Left of SettingsPanel)
        // Should appear at Right Edge (Left of 0-width Target), NOT at Left Edge of screen.

        final controller = PanelLayoutController();
        const spacerPanel = PanelId('spacer');
        const settingsPanel = PanelId('settings_panel');
        const changePanel = PanelId('settings_change_panel');

        // 0. Spacer Panel (Flexible) - Pushes settings to right
        controller.registerPanel(
          spacerPanel,
          builder: (context, _) => Container(color: Colors.green),
          sizing: const FlexibleSizing(1),
          mode: PanelMode.inline,
          anchor: PanelAnchor.left,
        );

        // 1. Register Hidden Target (Inline, Right)
        // Real Scenario: ContentSizing + Hidden = SizedBox.shrink()
        controller.registerPanel(
          settingsPanel,
          builder:
              (context, _) =>
                  Container(width: 100, height: 100, color: Colors.red),
          sizing: const ContentSizing(),
          mode: PanelMode.inline,
          anchor: PanelAnchor.right,
          isVisible: false, // Hidden!
        );

        // 2. Register Overlay (Anchored Left of Target)
        controller.registerPanel(
          changePanel,
          builder:
              (context, _) =>
                  Container(width: 200, height: 200, color: Colors.blue),
          sizing: const FixedSizing(200),
          mode: PanelMode.overlay,
          anchor: PanelAnchor.left,
          anchorPanel: settingsPanel,
          isVisible: true,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: PanelScope(
              controller: controller,
              child: PanelArea(
                panelLayoutController: controller,
                panelIds: const [spacerPanel, settingsPanel, changePanel],
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify position of ChangePanel
        final changeFinder = find.byKey(
          ValueKey('panel_${changePanel.value}_visible'),
        );
        final renderBox = tester.renderObject(changeFinder) as RenderBox;
        final position = renderBox.localToGlobal(Offset.zero);
        final screenSize =
            tester.binding.window.physicalSize /
            tester.binding.window.devicePixelRatio;

        // Expectation:
        // Screen Width is usually 800 in tests.
        // SettingsPanel is at 800.
        // ChangePanel (Left of Settings) should be at 800 - 200 = 600.
        // If it fell back to Global Left, it would be at 0.

        // We expect it to be on the RIGHT side.
        expect(
          position.dx,
          greaterThan(screenSize.width / 2),
          reason: 'Panel should be on the right side',
        );
        expect(
          position.dx,
          closeTo(screenSize.width - 200, 2.0),
        ); // 1.0 tolerance might be tight for double math
      },
    );
    */
  });
}
