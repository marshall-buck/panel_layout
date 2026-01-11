import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/panel_layout.dart';

void main() {
  group('Scope Widget Tests', () {
    testWidgets('PanelScope.of throws if missing', (tester) async {
      await tester.pumpWidget(
        Builder(builder: (context) {
          expect(() => PanelLayout.of(context), throwsException);
          return Container();
        }),
      );
    });

    testWidgets('PanelScope.of(listen: false) returns controller', (tester) async {
      final controller = PanelLayoutController();
      late PanelLayoutController found;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PanelLayout(
            controller: controller,
            children: [
              SimplePanel(
                id: 'p1', 
                child: Builder(builder: (context) {
                  found = PanelScope.of(context, listen: false);
                  return Container();
                }),
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
      final controller = PanelLayoutController();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PanelLayout(
            controller: controller,
            children: [
              SimplePanel(
                id: 'p1', 
                child: Builder(builder: (context) {
                  builds++;
                  PanelDataScope.of(context); // register dependency
                  return Container();
                }),
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

class SimplePanel extends BasePanel {
  SimplePanel({super.key, required String id, required super.child}) : super(id: PanelId(id));
}
