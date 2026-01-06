import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/src/panel_layout.dart';
import 'package:panel_layout/src/panel_layout_controller.dart';

void main() {
  group('PanelLayout', () {
    testWidgets('creates and provides controller', (tester) async {
      late PanelLayoutController capturedController;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PanelLayout(
            builder: (context, controller) {
              capturedController = controller;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(capturedController, isNotNull);
      
      // Verify it's in scope
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PanelLayout(
            builder: (context, controller) {
               expect(PanelLayout.of(context), controller);
               return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('disposes controller on unmount', (tester) async {
      // It's hard to verify dispose directly since we can't access the private _controller state 
      // after the widget is gone, and standard ChangeNotifier.dispose() doesn't have side effects we can observe easily 
      // without mocking.
      // But we can verify that the widget tree builds correctly and cleans up without error.
      
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PanelLayout(
            builder: (context, controller) => const SizedBox(),
          ),
        ),
      );
      
      // Remove it
      await tester.pumpWidget(const SizedBox());
      
      // Expect no errors.
    });

    testWidgets('PanelLayout.of returns controller', (tester) async {
       late PanelLayoutController controller;
       
       await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: PanelLayout(
            builder: (context, c) {
              controller = c;
              return Builder(
                builder: (innerContext) {
                  expect(PanelLayout.of(innerContext), controller);
                  return const SizedBox();
                },
              );
            },
          ),
        ),
      );
    });
    
    testWidgets('PanelLayout.of throws if missing', (tester) async {
       await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (context) {
              expect(
                () => PanelLayout.of(context),
                throwsA(isA<Exception>()),
              );
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });
}
