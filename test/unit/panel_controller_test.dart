import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/src/panel_controller.dart';
import 'package:panel_layout/src/panel_data.dart';

void main() {
  group('PanelController', () {
    late PanelController controller;
    const panelId = PanelId('test_panel');

    setUp(() {
      controller = PanelController(
        id: panelId,
        sizing: const FixedSizing(200.0),
        mode: PanelMode.inline,
        anchor: PanelAnchor.left,
      );
    });

    test('initial state is correct', () {
      expect(controller.id, panelId);
      expect(controller.sizing, isA<FixedSizing>());
      expect((controller.sizing as FixedSizing).size, 200.0);
      expect(controller.mode, PanelMode.inline);
      expect(controller.anchor, PanelAnchor.left);
      expect(controller.isCollapsed, false);
      expect(controller.isVisible, true);
      expect(controller.effectiveSize, 200.0);
    });

    test('resize updates fixed size', () {
      controller.resize(250.0);
      expect((controller.sizing as FixedSizing).size, 250.0);
      expect(controller.effectiveSize, 250.0);
    });

    test('resize respects constraints', () {
      controller = PanelController(
        id: panelId,
        sizing: const FixedSizing(100.0),
        mode: PanelMode.inline,
        anchor: PanelAnchor.left,
        constraints: const PanelConstraints(minSize: 50.0, maxSize: 300.0),
      );

      controller.resize(400.0);
      expect((controller.sizing as FixedSizing).size, 300.0);

      controller.resize(20.0);
      expect((controller.sizing as FixedSizing).size, 50.0);
    });

    test('resize updates flexible weight', () {
      controller = PanelController(
        id: panelId,
        sizing: const FlexibleSizing(1.0),
        mode: PanelMode.inline,
        anchor: PanelAnchor.left,
      );

      controller.resize(2.0);
      expect((controller.sizing as FlexibleSizing).weight, 2.0);
      expect(controller.effectiveSize, 2.0);
    });

    test('resize ignored if not resizable', () {
      controller = PanelController(
        id: panelId,
        sizing: const FixedSizing(200.0),
        mode: PanelMode.inline,
        anchor: PanelAnchor.left,
        isResizable: false,
      );

      controller.resize(300.0);
      expect((controller.sizing as FixedSizing).size, 200.0);
    });

    test('resize ignored for ContentSizing', () {
      controller = PanelController(
        id: panelId,
        sizing: const ContentSizing(),
        mode: PanelMode.inline,
        anchor: PanelAnchor.left,
      );

      controller.resize(300.0);
      expect(controller.sizing, isA<ContentSizing>());
      expect(controller.effectiveSize, -1.0);
    });

    test('toggle collapses and expands', () {
      controller.toggle();
      expect(controller.isCollapsed, true);
      expect(controller.effectiveSize, controller.constraints.collapsedSize);

      controller.toggle();
      expect(controller.isCollapsed, false);
      expect(controller.effectiveSize, 200.0);
    });

    test('setVisible updates visibility', () {
      controller.setVisible(visible: false);
      expect(controller.isVisible, false);
      expect(controller.effectiveSize, 0.0);

      controller.setVisible(visible: true);
      expect(controller.isVisible, true);
      expect(controller.effectiveSize, 200.0);
    });

    test('setMode updates mode', () {
      controller.setMode(PanelMode.overlay);
      expect(controller.mode, PanelMode.overlay);
    });

    test('setVisuals updates visuals', () {
      final newVisuals = const PanelVisuals(
        animationDuration: Duration(seconds: 2),
      );
      controller.setVisuals(newVisuals);
      expect(controller.visuals, newVisuals);
    });

    test('notifyListeners is called on changes', () {
      var listenerCalled = false;
      controller.addListener(() => listenerCalled = true);

      controller.resize(210.0);
      expect(listenerCalled, true);
      listenerCalled = false;

      controller.toggle();
      expect(listenerCalled, true);
      listenerCalled = false;

      controller.setVisible(visible: false);
      expect(listenerCalled, true);
    });
  });
}
