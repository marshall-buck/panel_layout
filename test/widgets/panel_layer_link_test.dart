import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_panels/flutter_panels.dart';
import 'package:flutter_panels/src/widgets/animation/animated_panel.dart';

void main() {
  testWidgets('Overlay panel follows external LayerLink', (tester) async {
    final link = LayerLink();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: [
            // Target widget
            Positioned(
              left: 300,
              top: 200,
              child: CompositedTransformTarget(
                link: link,
                child: const SizedBox(width: 50, height: 50),
              ),
            ),

            // Panel Layout
            Positioned.fill(
              child: PanelArea(
                children: [
                  OverlayPanel(
                    id: const PanelId('follower'),
                    anchorLink: link,

                    child: const SizedBox(width: 100, height: 100),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    final panelRect = tester.getRect(find.byType(AnimatedPanel));

    // CompositedTransformFollower shifts the content.
    expect(panelRect.topLeft, const Offset(300.0, 200.0));

    // Verify that a Follower widget exists
    expect(find.byType(CompositedTransformFollower), findsOneWidget);
  });
}
