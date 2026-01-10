import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/panel_layout.dart';

void main() {
  const panelA = PanelId('panelA');
  const panelB = PanelId('panelB');

  group('Overlay Animation', () {
    testWidgets('Global Left Anchor slides from Left (-1, 0)', (tester) async {
      final controller = PanelLayoutController();
      controller.registerPanel(
        panelA,
        builder: (context, _) => const SizedBox(width: 100, height: 100),
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

      // Target (Right of screen)
      controller.registerPanel(
        panelA,
        builder: (context, _) => const SizedBox(width: 100, height: 100),
        sizing: const FixedSizing(100),
        mode: PanelMode.inline,
        anchor: PanelAnchor.right,
      );

      // Overlay anchored to Target (Left of Target)
      controller.registerPanel(
        panelB,
        builder: (context, _) => const SizedBox(width: 100, height: 100),
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

      // Logic:
      // Target is at Right. Overlay is Left of Target.
      // Panel slides OUT from the target.
      // Position relative to final spot: Starts at +1 (Right, inside Target), moves to 0 (Left of Target).
      expect(offset.dx, greaterThan(0));
      expect(offset.dx, lessThanOrEqualTo(1.0));
    });

    testWidgets('Overlay maintains size during exit animation', (tester) async {
      final controller = PanelLayoutController();
      controller.registerPanel(
        panelA,
        builder: (context, _) => Container(
          key: const Key('content'), 
          width: 300, 
          height: 300,
          color: Colors.red,
        ),
        sizing: const FixedSizing(300),
        mode: PanelMode.overlay,
        anchor: PanelAnchor.right,
        isVisible: true,
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

      // Verify initial visibility and size
      expect(find.byKey(const Key('content')), findsOneWidget);
      expect(tester.getSize(find.byKey(const Key('content'))).width, 300.0);

      // Close panel
      controller.getPanel(panelA)!.setVisible(visible: false);
      await tester.pump(); // Start exit animation (t=0)
      await tester.pump(const Duration(milliseconds: 500)); // Halfway

      // Verify it is STILL in tree and STILL has size
      expect(find.byKey(const Key('content')), findsOneWidget);
      expect(tester.getSize(find.byKey(const Key('content'))).width, 300.0, 
        reason: 'Panel should NOT shrink to 0 during exit animation');

      await tester.pumpAndSettle();
      
      // Now it should be gone
      expect(find.byKey(const Key('content')), findsNothing);
    });

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
          anchor: PanelAnchor.top,
        );

        // 1. Register Hidden Target (Inline, Right)
        controller.registerPanel(
          settingsPanel,
          builder: (context, _) => Container(width: 100, height: 100, color: Colors.red),
          sizing: const ContentSizing(),
          mode: PanelMode.inline,
          anchor: PanelAnchor.right,
          isVisible: false, // Hidden!
        );

        // 2. Register Overlay (Anchored Left of Target)
        controller.registerPanel(
          changePanel,
          builder: (context, _) => Container(width: 200, height: 200, color: Colors.blue),
          sizing: const FixedSizing(200),
          mode: PanelMode.overlay,
          anchor: PanelAnchor.left,
          anchorPanel: settingsPanel,
          isVisible: true,
        );

        // Fixed screen size
        tester.view.physicalSize = const Size(800, 600);
        tester.view.devicePixelRatio = 1.0;

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
        // Screen Width: 800.
        // SettingsPanel: Width 0 (Hidden). Positioned at 800 (Right Edge).
        // ChangePanel: Anchored Left of SettingsPanel.
        // Expected Right Edge = 800. Width = 200. Left Edge = 600.
        
        final changeFinder = find.byKey(
          ValueKey(changePanel), // Correct key logic from PanelArea
        );
        
        // Ensure Key matches what PanelArea uses.
        // PanelArea uses LayoutId(id: panel.id, child: LayoutPanel(key: ValueKey(panel.id)))
        // So find.byKey(ValueKey(PanelId('...'))) should work.
        expect(changeFinder, findsOneWidget);
        
        final rect = tester.getRect(changeFinder);

        expect(rect.right, closeTo(800.0, 0.2), reason: 'Overlay Right should match Screen Right (Target)');
        expect(rect.left, closeTo(600.0, 0.2), reason: 'Overlay Left should be Screen Width - Overlay Width');
      },
    );
  });
}