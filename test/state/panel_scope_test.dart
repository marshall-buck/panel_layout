import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/panel_layout.dart';

class TestChild extends StatelessWidget {
  const TestChild({super.key, required this.onBuild});
  final VoidCallback onBuild;

  @override
  Widget build(BuildContext context) {
    PanelScope.of(context);
    onBuild();
    return const SizedBox();
  }
}

void main() {
  group('PanelScope', () {
    testWidgets('provides controller to descendants', (tester) async {
      final controller = PanelLayoutController();
      late PanelLayoutController retrievedController;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PanelScope(
            controller: controller,
            child: Builder(
              builder: (context) {
                retrievedController = PanelScope.of(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      expect(retrievedController, controller);
    });

    testWidgets('updateShouldNotify works correctly', (tester) async {
      final controller1 = PanelLayoutController();
      final controller2 = PanelLayoutController();

      var buildCount = 0;

      // Use a const child widget so it only rebuilds if dependencies change
      final child = TestChild(onBuild: () => buildCount++);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PanelScope(controller: controller1, child: child),
        ),
      );

      expect(buildCount, 1);

      // Rebuild with same controller -> should not rebuild child
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PanelScope(controller: controller1, child: child),
        ),
      );

      expect(buildCount, 1); // No change

      // Rebuild with new controller -> should rebuild child
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PanelScope(controller: controller2, child: child),
        ),
      );

      expect(buildCount, 2);
    });

    testWidgets('throws if not found', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (context) {
              expect(() => PanelScope.of(context), throwsA(isA<Exception>()));
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });
}
