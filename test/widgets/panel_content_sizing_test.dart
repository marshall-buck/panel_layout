import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/panel_layout.dart';
import 'package:panel_layout/src/widgets/animation/animated_panel.dart';
import '../utils/test_content_panel.dart';

Finder findPanel(String id) => find.byWidgetPredicate(
  (w) => w is AnimatedPanel && w.config.id == PanelId(id),
);

void main() {


  testWidgets('InlinePanel works with ListView (unbounded height)', (
    tester,
  ) async {
    // Tests that SingleChildScrollView (the fix) allows ListView to work
    // without "unbounded height" error in an InlinePanel (horizontal layout).
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 800,
            height: 600,
            child: PanelLayout(
              children: [
                InlinePanel(
                  id: const PanelId('list'),
                  width: 200,
                  child: ListView(
                    children: const [Text('Item 1'), Text('Item 2')],
                  ),
                ),
                TestContentPanel(
                  id: const PanelId('fill'),
                  flexOverride: 1,
                  child: Container(),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Item 1'), findsOneWidget);
    expect(tester.getSize(findPanel('list')).width, 200.0);
  });

  testWidgets('OverlayPanel works with ListView (shrinkWrap: true)', (
    tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 800,
            height: 600,
            child: PanelLayout(
              children: [
                TestContentPanel(
                  id: const PanelId('bg'),
                  flexOverride: 1,
                  child: Container(),
                ),
                OverlayPanel(
                  id: const PanelId('overlay'),
                  width: 200,

                  // Content sizing height (requires shrinkWrap for ListView if no height)
                  child: ListView(
                    shrinkWrap: true,
                    children: const [
                      SizedBox(height: 50, child: Text('Item 1')),
                      SizedBox(height: 50, child: Text('Item 2')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Item 1'), findsOneWidget);
    final size = tester.getSize(findPanel('overlay'));
    expect(size.width, 200.0);
    // Height should be 100 + padding/decoration if any.
    // BasePanel has no default padding/decoration size unless themed?
    // AnimatedPanel might add toggle button?
    // The panel is 50+50 = 100 height.
    expect(size.height, 100.0);
  });

  testWidgets('OverlayPanel respects fixed width and height', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 800,
            height: 600,
            child: PanelLayout(
              children: [
                TestContentPanel(
                  id: const PanelId('bg'),
                  flexOverride: 1,
                  child: Container(),
                ),
                OverlayPanel(
                  id: const PanelId('fixed'),
                  width: 150,
                  height: 150,

                  child: const Center(child: Text('Fixed')),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final size = tester.getSize(findPanel('fixed'));
    expect(size.width, 150.0);
    expect(size.height, 150.0);
  });

  testWidgets('InlinePanel works with SingleChildScrollView', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 800,
            height: 600,
            child: PanelLayout(
              children: [
                InlinePanel(
                  id: const PanelId('scroll'),
                  width: 200,
                  child: SingleChildScrollView(
                    child: Column(
                      children: List.generate(
                        50,
                        (index) => Text('Item $index'),
                      ),
                    ),
                  ),
                ),
                TestContentPanel(
                  id: const PanelId('fill'),
                  flexOverride: 1,
                  child: Container(),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Item 0'), findsOneWidget);
    expect(tester.getSize(findPanel('scroll')).width, 200.0);
  });

  testWidgets('OverlayPanel works with SingleChildScrollView', (tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 800,
            height: 600,
            child: PanelLayout(
              children: [
                TestContentPanel(
                  id: const PanelId('bg'),
                  flexOverride: 1,
                  child: Container(),
                ),
                OverlayPanel(
                  id: const PanelId('overlay_scroll'),
                  width: 200,
                  height: 300,

                  child: SingleChildScrollView(
                    child: Column(
                      children: List.generate(
                        50,
                        (index) => Text('Overlay Item $index'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Overlay Item 0'), findsOneWidget);
    final size = tester.getSize(findPanel('overlay_scroll'));
    expect(size.width, 200.0);
    expect(size.height, 300.0);
  });
}
