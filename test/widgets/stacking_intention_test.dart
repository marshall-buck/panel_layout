import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/panel_layout.dart';

void main() {
  const settingsPanelId = PanelId('settings');
  const changePanelId = PanelId('change');

  group('Intention: Stacking & Animation', () {
    testWidgets(
      'Overlay slides from BEHIND anchor when placed before anchor in panelIds',
      (tester) async {
        final controller = PanelLayoutController();

        // 1. Setup Panels
        // Settings (Anchor): Right, Inline.
        controller.registerPanel(
          settingsPanelId,
          builder: (context, _) => Container(
            color: Colors.blue,
            child: const Text('Settings'),
          ),
          sizing: const FixedSizing(200),
          mode: PanelMode.inline,
          anchor: PanelAnchor.right,
        );

        // Change (Overlay): Left of Settings.
        controller.registerPanel(
          changePanelId,
          builder: (context, _) => Container(
            color: Colors.red,
            child: const Text('Change'),
          ),
          sizing: const FixedSizing(200),
          mode: PanelMode.overlay,
          anchor: PanelAnchor.left,
          anchorPanel: settingsPanelId,
          isVisible: true, // Start visible to check static stacking first
        );

        // 2. Pump Widget with ORDER: [Change, Settings]
        // This intends for "Change" to be BEHIND "Settings".
        await tester.pumpWidget(
          MaterialApp(
            home: PanelScope(
              controller: controller,
              child: PanelArea(
                panelLayoutController: controller,
                panelIds: const [changePanelId, settingsPanelId],
              ),
            ),
          ),
        );

        // 3. Verify Paint Order
        // In CustomMultiChildLayout, children are painted in list order.
        // We expect Change (Red) first, Settings (Blue) second.
        
        final layout = tester.widget<CustomMultiChildLayout>(find.byType(CustomMultiChildLayout));
        final children = layout.children;
        
        // Find LayoutIds
        final changeWidget = children.firstWhere((w) => (w as LayoutId).id == changePanelId) as LayoutId;
        final settingsWidget = children.firstWhere((w) => (w as LayoutId).id == settingsPanelId) as LayoutId;
        
        final changeIndex = children.indexOf(changeWidget);
        final settingsIndex = children.indexOf(settingsWidget);
        
        expect(changeIndex, lessThan(settingsIndex), reason: 'Change Panel should paint BEFORE Settings Panel (Behind)');
      },
    );

    testWidgets('Overlay slides OVER anchor when placed after anchor in panelIds', (tester) async {
       final controller = PanelLayoutController();

        controller.registerPanel(
          settingsPanelId,
          builder: (context, _) => const Text('Settings'),
          sizing: const FixedSizing(200),
          mode: PanelMode.inline,
          anchor: PanelAnchor.right,
        );

        controller.registerPanel(
          changePanelId,
          builder: (context, _) => const Text('Change'),
          sizing: const FixedSizing(200),
          mode: PanelMode.overlay,
          anchor: PanelAnchor.left,
          anchorPanel: settingsPanelId,
          isVisible: true,
        );

        // ORDER: [Settings, Change]
        await tester.pumpWidget(
          MaterialApp(
            home: PanelScope(
              controller: controller,
              child: PanelArea(
                panelLayoutController: controller,
                panelIds: const [settingsPanelId, changePanelId],
              ),
            ),
          ),
        );

        final layout = tester.widget<CustomMultiChildLayout>(find.byType(CustomMultiChildLayout));
        final children = layout.children;
        
        final settingsIndex = children.indexWhere((w) => (w as LayoutId).id == settingsPanelId);
        final changeIndex = children.indexWhere((w) => (w as LayoutId).id == changePanelId);
        
        expect(changeIndex, greaterThan(settingsIndex), reason: 'Change Panel should paint AFTER Settings Panel (Over)');
    });

    testWidgets('Overlay animates out and back in smoothly (no instant disappear)', (tester) async {
      final controller = PanelLayoutController();

      controller.registerPanel(
        settingsPanelId,
        builder: (context, _) => const SizedBox(width: 200, height: 600),
        sizing: const FixedSizing(200),
        mode: PanelMode.inline,
        anchor: PanelAnchor.right,
      );

      controller.registerPanel(
        changePanelId,
        builder: (context, _) => Container(key: const Key('content'), color: Colors.red),
        sizing: const FixedSizing(200),
        mode: PanelMode.overlay,
        anchor: PanelAnchor.left,
        anchorPanel: settingsPanelId,
        isVisible: false, // Start hidden
        visuals: const PanelVisuals(
          animationDuration: Duration(milliseconds: 1000), // Slow animation
          animationCurve: Curves.linear,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PanelScope(
            controller: controller,
            child: PanelArea(
              panelLayoutController: controller,
              panelIds: const [changePanelId, settingsPanelId], // Behind
            ),
          ),
        ),
      );

      // 1. Trigger Open
      controller.getPanel(changePanelId)!.setVisible(visible: true);
      await tester.pump(); // Start frame
      await tester.pump(const Duration(milliseconds: 500)); // Halfway

      // Verify it is visible and has size
      expect(find.byKey(const Key('content')), findsOneWidget);
      expect(tester.getSize(find.byKey(const Key('content'))).width, 200.0);

      await tester.pumpAndSettle(); // Fully Open

      // 2. Trigger Close
      controller.getPanel(changePanelId)!.setVisible(visible: false);
      await tester.pump(); // Start exit frame

      // It should NOT disappear instantly.
      // Opacity or Slide should be running.
      // Widget should be in tree.
      expect(find.byKey(const Key('content')), findsOneWidget, reason: 'Should persist at start of exit');
      
      await tester.pump(const Duration(milliseconds: 100)); 
      expect(find.byKey(const Key('content')), findsOneWidget, reason: 'Should persist during exit');

      await tester.pump(const Duration(milliseconds: 500)); // Halfway
      expect(find.byKey(const Key('content')), findsOneWidget, reason: 'Should persist halfway through exit');

      await tester.pumpAndSettle(); // Done
      
      // Now it should be gone
      expect(find.byKey(const Key('content')), findsNothing);
    });
  });
}
