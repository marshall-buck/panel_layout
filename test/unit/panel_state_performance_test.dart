import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_panels/src/models/panel_style.dart';
import 'package:flutter_panels/src/models/panel_id.dart';
import 'package:flutter_panels/src/state/panel_state_manager.dart';
import 'package:flutter_panels/src/widgets/panels/inline_panel.dart';
import 'package:flutter/widgets.dart';

class TestTickerProvider extends TickerProvider {
  const TestTickerProvider();

  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}

void main() {
  group('PanelStateManager Performance', () {
    late PanelStateManager manager;

    setUp(() {
      manager = PanelStateManager();
    });

    tearDown(() {
      manager.dispose();
    });

    testWidgets('Animation ticks MUST NOT trigger global notifyListeners', (tester) async {
      final panelId = PanelId('test_panel');
      final panel = InlinePanel(
        id: panelId,
        width: 100,
        child: Container(),
        // Use a long duration to ensure we get many ticks
        animationDuration: const Duration(seconds: 1), 
      );

      // Use a TickerProvider that hooks into the SchedulerBinding
      manager.reconcile([panel], const PanelStyle(), const TestTickerProvider());

      int notifyCount = 0;
      manager.addListener(() {
        notifyCount++;
      });

      // 1. Trigger Visibility Change
      // This SHOULD trigger ONE notification for the state change (visible: true -> false)
      manager.setVisible(panelId, false);
      
      // Initial state change notification
      expect(notifyCount, equals(1), reason: 'Should notify once for state change');

      // 2. Advance Animation
      final controller = manager.getAnimationController(panelId)!;
      expect(controller.isAnimating, isTrue);

      // Simulate multiple frames
      // We pump with a duration to advance the clock. 
      // Since we used Ticker(), this hooks into the binding tester controls.
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // The count should remain at 1. 
      // If it increased, it means the animation controller is driving the manager updates.
      expect(notifyCount, equals(1), 
        reason: 'Animation ticks caused global rebuilds! Regression detected. '
                'PanelStateManager.notifyListeners was called ${notifyCount - 1} extra times during animation.');
      
      // finish animation
      await tester.pump(const Duration(seconds: 1));
      expect(controller.isAnimating, isFalse);
    });

    testWidgets('Collapse ticks MUST NOT trigger global notifyListeners', (tester) async {
      final panelId = PanelId('test_panel');
      final panel = InlinePanel(
        id: panelId,
        width: 100,
        initialCollapsed: false,
        child: Container(),
        animationDuration: const Duration(seconds: 1), 
      );

      manager.reconcile([panel], const PanelStyle(), const TestTickerProvider());

      int notifyCount = 0;
      manager.addListener(() {
        notifyCount++;
      });

      // 1. Trigger Collapse Change
      manager.setCollapsed(panelId, true);
      expect(notifyCount, equals(1), reason: 'Should notify once for state change');

      // 2. Advance Animation
      final controller = manager.getCollapseController(panelId)!;
      expect(controller.isAnimating, isTrue);

      // Simulate multiple frames
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      expect(notifyCount, equals(1), 
        reason: 'Collapse animation ticks caused global rebuilds! Regression detected.');

      // Finish animation to clean up
      await tester.pump(const Duration(seconds: 1));
      expect(controller.isAnimating, isFalse);
    });
  });
}
