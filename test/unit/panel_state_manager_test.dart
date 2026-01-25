import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/src/layout/panel_style.dart';
import 'package:panel_layout/src/models/panel_id.dart';
import 'package:panel_layout/src/state/panel_state_manager.dart';
import 'package:panel_layout/src/widgets/panels/inline_panel.dart';
import 'package:flutter/widgets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('PanelStateManager', () {
    late PanelStateManager manager;
    late TestVSync vsync;

    setUp(() {
      manager = PanelStateManager();
      vsync = const TestVSync();
    });

    tearDown(() {
      manager.dispose();
    });

    test('reconcile adds new panels', () {
      final panel1 = InlinePanel(
        id: PanelId('1'),
        width: 100,
        child: Container(),
      );
      final panel2 = InlinePanel(id: PanelId('2'), flex: 1, child: Container());

      manager.reconcile([panel1, panel2], const PanelStyle(), vsync);

      expect(manager.getState(PanelId('1')), isNotNull);
      expect(manager.getState(PanelId('2')), isNotNull);
      expect(manager.getState(PanelId('3')), isNull);
    });

    test('reconcile removes orphaned panels', () {
      final panel1 = InlinePanel(id: PanelId('1'), child: Container());

      manager.reconcile([panel1], const PanelStyle(), vsync);
      expect(manager.getState(PanelId('1')), isNotNull);

      manager.reconcile([], const PanelStyle(), vsync);
      expect(manager.getState(PanelId('1')), isNull);
    });

    test('setVisible updates state and notifies listeners', () {
      final panel1 = InlinePanel(id: PanelId('1'), child: Container());
      manager.reconcile([panel1], const PanelStyle(), vsync);

      bool notified = false;
      manager.addListener(() => notified = true);

      manager.setVisible(PanelId('1'), false);

      expect(manager.getState(PanelId('1'))!.visible, isFalse);
      expect(notified, isTrue);

      // Check animation controller
      final controller = manager.getAnimationController(PanelId('1'));
      expect(controller!.status, equals(AnimationStatus.reverse));
    });

    test('setCollapsed updates state and notifies listeners', () {
      final panel1 = InlinePanel(id: PanelId('1'), child: Container());
      manager.reconcile([panel1], const PanelStyle(), vsync);

      bool notified = false;
      manager.addListener(() => notified = true);

      manager.setCollapsed(PanelId('1'), true);

      expect(manager.getState(PanelId('1'))!.collapsed, isTrue);
      expect(notified, isTrue);

      // Check animation controller
      final controller = manager.getCollapseController(PanelId('1'));
      expect(controller!.status, equals(AnimationStatus.forward));
    });

    test('updateSize updates state and notifies listeners', () {
      final panel1 = InlinePanel(
        id: PanelId('1'),
        width: 100,
        child: Container(),
      );
      manager.reconcile([panel1], const PanelStyle(), vsync);

      bool notified = false;
      manager.addListener(() => notified = true);

      manager.updateSize(PanelId('1'), 200);

      expect(manager.getState(PanelId('1'))!.size, equals(200));
      expect(notified, isTrue);
    });
  });
}
