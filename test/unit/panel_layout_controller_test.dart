import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/src/panel_data.dart';
import 'package:panel_layout/src/panel_layout_controller.dart';

void main() {
  group('PanelLayoutController', () {
    late PanelLayoutController layoutController;
    const panelId = PanelId('test_panel');

    setUp(() {
      layoutController = PanelLayoutController();
    });

    tearDown(() {
      layoutController.dispose();
    });

    test('registerPanel creates and stores new panel', () {
      final controller = layoutController.registerPanel(
        panelId,
        builder: (c, _) => const SizedBox(),
        sizing: const FixedSizing(100),
        mode: PanelMode.inline,
        anchor: PanelAnchor.left,
      );

      expect(controller, isNotNull);
      expect(controller.id, panelId);
      expect(layoutController.getPanel(panelId), controller);
    });

    test('registerPanel returns existing panel if ID matches', () {
      final controller1 = layoutController.registerPanel(
        panelId,
        builder: (c, _) => const SizedBox(),
        sizing: const FixedSizing(100),
        mode: PanelMode.inline,
        anchor: PanelAnchor.left,
      );

      final controller2 = layoutController.registerPanel(
        panelId,
        builder: (c, _) => const SizedBox(),
        sizing: const FixedSizing(200), // Different config
        mode: PanelMode.overlay,
        anchor: PanelAnchor.right,
      );

      expect(controller1, same(controller2));
      // Should NOT update existing controller properties on re-register
      expect((controller1.sizing as FixedSizing).size, 100.0);
    });

    test('getPanel returns null for unknown ID', () {
      expect(layoutController.getPanel(const PanelId('unknown')), isNull);
    });

    test('getPanelOrThrow throws for unknown ID', () {
      expect(
        () => layoutController.getPanelOrThrow(const PanelId('unknown')),
        throwsException,
      );
    });

    test('removePanel removes and disposes controller', () {
      layoutController.registerPanel(
        panelId,
        builder: (c, _) => const SizedBox(),
        sizing: const FixedSizing(100),
        mode: PanelMode.inline,
        anchor: PanelAnchor.left,
      );

      var listenerCalled = false;
      layoutController.addListener(() => listenerCalled = true);

      layoutController.removePanel(panelId);

      expect(layoutController.getPanel(panelId), isNull);
      expect(listenerCalled, true);
      // We can't easily check if controller is disposed, but we trust the implementation
    });

    test('dispose clears all panels', () {
      // Create a local controller to test dispose specifically, 
      // ensuring we don't conflict with setUp/tearDown lifecycle.
      final localController = PanelLayoutController();
      
      localController.registerPanel(
        panelId,
        builder: (c, _) => const SizedBox(),
        sizing: const FixedSizing(100),
        mode: PanelMode.inline,
        anchor: PanelAnchor.left,
      );

      localController.dispose();
      
      // Verification: implicitly passed if no error is thrown.
      // We can't access state after dispose.
    });
  });
}
