import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/panel_layout.dart';
import 'package:panel_layout/src/panel_resize_handle.dart';

void main() {
  group('Edge Cases & Stress Testing', () {
    late PanelLayoutController layoutController;

    setUp(() {
      layoutController = PanelLayoutController();
    });

    tearDown(() {
      layoutController.dispose();
    });

    testWidgets('Panel with 0 size (FixedSizing)', (tester) async {
      layoutController.registerPanel(
        const PanelId('zero'),
        sizing: const FixedSizing(0),
        mode: PanelMode.inline,
        anchor: PanelAnchor.left,
      );
      layoutController.registerPanel(
        const PanelId('content'),
        sizing: const FlexibleSizing(1),
        mode: PanelMode.inline,
        anchor: PanelAnchor.left,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PanelScope(
            controller: layoutController,
            child: PanelArea(
              panelLayoutController: layoutController,
              panelIds: const [PanelId('zero'), PanelId('content')],
              panelBuilder: (context, id) => Text('Content $id'),
            ),
          ),
        ),
      );

      expect(find.text('Content PanelId(zero)'), findsOneWidget);
      // It exists but has 0 width (plus resize handle width?)
      // We expect it to be practically invisible but present in tree
    });

    testWidgets('Empty PanelArea does not crash', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PanelScope(
            controller: layoutController,
            child: PanelArea(
              panelLayoutController: layoutController,
              panelIds: const [],
              panelBuilder: (context, id) => Text('Content $id'),
            ),
          ),
        ),
      );

      expect(find.byType(PanelArea), findsOneWidget);
      // Should likely render an empty Row/Column
    });

    testWidgets('Rapid visibility toggling', (tester) async {
      final panel = layoutController.registerPanel(
        const PanelId('toggle'),
        sizing: const FixedSizing(100),
        mode: PanelMode.inline,
        anchor: PanelAnchor.left,
        visuals: const PanelVisuals(animationDuration: Duration(milliseconds: 200)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PanelScope(
            controller: layoutController,
            child: PanelArea(
              panelLayoutController: layoutController,
              panelIds: const [PanelId('toggle')],
              panelBuilder: (context, id) => Container(color: Colors.red),
            ),
          ),
        ),
      );

      // Toggle off
      panel.setVisible(visible: false);
      await tester.pump(const Duration(milliseconds: 50)); // Start animation

      // Toggle on immediately
      panel.setVisible(visible: true);
      await tester.pump(const Duration(milliseconds: 50)); // Should reverse

      // Toggle off again
      panel.setVisible(visible: false);
      await tester.pumpAndSettle();

      // Final state: hidden (width 0)
      // Check that it's rendered but likely 0 size.
      // We are just verifying no crash/race condition logic.
    });

    testWidgets('Theme switching updates visuals', (tester) async {
      final themeData = ValueNotifier<PanelThemeData>(
        const PanelThemeData(
          resizeHandleDecoration: BoxDecoration(
            color: Colors.red,
          ),
        ),
      );

      layoutController.registerPanel(
        const PanelId('p1'),
        sizing: const FixedSizing(100),
        mode: PanelMode.inline,
        anchor: PanelAnchor.left,
      );
      layoutController.registerPanel(
        const PanelId('p2'),
        sizing: const FlexibleSizing(1),
        mode: PanelMode.inline,
        anchor: PanelAnchor.left,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ValueListenableBuilder<PanelThemeData>(
            valueListenable: themeData,
            builder: (context, theme, _) {
              return PanelTheme(
                data: theme,
                child: PanelScope(
                  controller: layoutController,
                  child: PanelArea(
                    panelLayoutController: layoutController,
                    panelIds: const [PanelId('p1'), PanelId('p2')],
                    panelBuilder: (context, id) => const SizedBox(),
                  ),
                ),
              );
            },
          ),
        ),
      );

      // Find resize handle's internal AnimatedContainer
      final handleFinder = find.descendant(
        of: find.byType(PanelResizeHandle), 
        matching: find.byType(AnimatedContainer)
      );
      
      final animatedContainer = tester.widget<AnimatedContainer>(handleFinder.first);
      expect((animatedContainer.decoration as BoxDecoration).color, Colors.red);

      // Update theme
      themeData.value = const PanelThemeData(
        resizeHandleDecoration: BoxDecoration(
          color: Colors.blue,
        ),
      );
      await tester.pumpAndSettle();

      final animatedContainer2 = tester.widget<AnimatedContainer>(handleFinder.first);
      expect((animatedContainer2.decoration as BoxDecoration).color, Colors.blue);
    });
  });
}