import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_panels/flutter_panels.dart';

void main() {
  group('Scope Widget Tests', () {
    testWidgets('PanelScope.of throws if missing', (tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            expect(() => PanelArea.of(context), throwsException);
            return Container();
          },
        ),
      );
    });

    testWidgets('PanelScope.of(listen: false) returns controller', (
      tester,
    ) async {
      final controller = PanelAreaController();
      late PanelAreaController found;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PanelArea(
            controller: controller,
            children: [
              InlinePanel(
                id: const PanelId('p1'),
                child: Builder(
                  builder: (context) {
                    found = PanelScope.of(context, listen: false);
                    return Container();
                  },
                ),
              ),
            ],
          ),
        ),
      );

      expect(found, controller);
    });

    testWidgets('PanelDataScope notifyDependent returns true', (tester) async {
      // InheritedModel.inheritFrom registers a dependency.
      // We can trigger updateShouldNotifyDependent by changing state.
      int builds = 0;
      final controller = PanelAreaController();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PanelArea(
            controller: controller,
            children: [
              InlinePanel(
                id: const PanelId('p1'),
                child: Builder(
                  builder: (context) {
                    builds++;
                    PanelDataScope.of(context); // register dependency
                    return Container();
                  },
                ),
              ),
            ],
          ),
        ),
      );

      expect(builds, 1);
      controller.toggleVisible(const PanelId('p1'));
      await tester.pump();
      // Should rebuild because dependency was notified
      expect(builds, greaterThan(1));
    });
  });
}
