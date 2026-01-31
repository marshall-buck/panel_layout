import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_panels/flutter_panels.dart';
import 'package:flutter_panels/src/widgets/animation/animated_panel.dart';
import 'package:flutter_panels/src/widgets/internal/panel_resize_handle.dart';
import '../utils/test_content_panel.dart';

Finder findPanel(String id) => find.byWidgetPredicate(
  (w) => w is AnimatedPanel && w.config.id == PanelId(id),
);

void main() {
  group('Panel State Persistence', () {
    testWidgets('Preserves size when preserveLayoutState is true', (
      tester,
    ) async {
      bool showSidebar = true;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return Directionality(
              textDirection: TextDirection.ltr,
              child: Center(
                child: SizedBox(
                  width: 800,
                  height: 600,
                  child: PanelArea(
                    children: [
                      if (showSidebar)
                        const InlinePanel(
                          id: PanelId('sidebar'),
                          width: 200,
                          preserveLayoutState: true,
                          anchor: PanelAnchor.left,
                          child: SizedBox.expand(),
                        ),
                      const TestContentPanel(
                        id: PanelId('content'),
                        layoutWeightOverride: 1,
                        child: SizedBox.expand(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );

      // 1. Initial size check
      expect(tester.getSize(findPanel('sidebar')).width, 200);

      // 2. Simulate a resize
      final handle = find.byType(PanelResizeHandle);
      await tester.drag(handle, const Offset(100, 0));
      await tester.pumpAndSettle();

      expect(tester.getSize(findPanel('sidebar')).width, 300);

      // 3. Remove the sidebar
      showSidebar = false;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return Directionality(
              textDirection: TextDirection.ltr,
              child: Center(
                child: SizedBox(
                  width: 800,
                  height: 600,
                  child: PanelArea(
                    children: [
                      if (showSidebar)
                        const InlinePanel(
                          id: PanelId('sidebar'),
                          width: 200,
                          preserveLayoutState: true,
                          anchor: PanelAnchor.left,
                          child: SizedBox.expand(),
                        ),
                      const TestContentPanel(
                        id: PanelId('content'),
                        layoutWeightOverride: 1,
                        child: SizedBox.expand(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(findPanel('sidebar'), findsNothing);

      // 4. Re-add the sidebar
      showSidebar = true;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return Directionality(
              textDirection: TextDirection.ltr,
              child: Center(
                child: SizedBox(
                  width: 800,
                  height: 600,
                  child: PanelArea(
                    children: [
                      if (showSidebar)
                        const InlinePanel(
                          id: PanelId('sidebar'),
                          width: 200, // Original default
                          preserveLayoutState: true,
                          anchor: PanelAnchor.left,
                          child: SizedBox.expand(),
                        ),
                      const TestContentPanel(
                        id: PanelId('content'),
                        layoutWeightOverride: 1,
                        child: SizedBox.expand(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      // 5. Verify size is preserved (300, not 200)
      expect(tester.getSize(findPanel('sidebar')).width, 300);
    });

    testWidgets('Resets size when preserveLayoutState is false', (
      tester,
    ) async {
      bool showSidebar = true;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return Directionality(
              textDirection: TextDirection.ltr,
              child: Center(
                child: SizedBox(
                  width: 800,
                  height: 600,
                  child: PanelArea(
                    children: [
                      if (showSidebar)
                        const InlinePanel(
                          id: PanelId('sidebar'),
                          width: 200,
                          preserveLayoutState: false,
                          anchor: PanelAnchor.left,
                          child: SizedBox.expand(),
                        ),
                      const TestContentPanel(
                        id: PanelId('content'),
                        layoutWeightOverride: 1,
                        child: SizedBox.expand(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );

      // 1. Resize
      await tester.drag(find.byType(PanelResizeHandle), const Offset(100, 0));
      await tester.pumpAndSettle();
      expect(tester.getSize(findPanel('sidebar')).width, 300);

      // 2. Remove
      showSidebar = false;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return Directionality(
              textDirection: TextDirection.ltr,
              child: Center(
                child: SizedBox(
                  width: 800,
                  height: 600,
                  child: PanelArea(
                    children: [
                      if (showSidebar)
                        const InlinePanel(
                          id: PanelId('sidebar'),
                          width: 200,
                          preserveLayoutState: false,
                          anchor: PanelAnchor.left,
                          child: SizedBox.expand(),
                        ),
                      const TestContentPanel(
                        id: PanelId('content'),
                        layoutWeightOverride: 1,
                        child: SizedBox.expand(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(findPanel('sidebar'), findsNothing);

      // 3. Re-add
      showSidebar = true;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return Directionality(
              textDirection: TextDirection.ltr,
              child: Center(
                child: SizedBox(
                  width: 800,
                  height: 600,
                  child: PanelArea(
                    children: [
                      if (showSidebar)
                        const InlinePanel(
                          id: PanelId('sidebar'),
                          width: 200,
                          preserveLayoutState: false,
                          anchor: PanelAnchor.left,
                          child: SizedBox.expand(),
                        ),
                      const TestContentPanel(
                        id: PanelId('content'),
                        layoutWeightOverride: 1,
                        child: SizedBox.expand(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      // 4. Verify size is reset to 200
      expect(tester.getSize(findPanel('sidebar')).width, 200);
    });
  });
}
