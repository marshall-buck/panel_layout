import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_panels/flutter_panels.dart';

void main() {
  group('Rendering Optimizations & Stability', () {
    testWidgets('AnimatedVerticalPanel: Removes Opacity/IgnorePointer when stable', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PanelArea(
            children: [
              InlinePanel(
                id: const PanelId('top'),
                anchor: PanelAnchor.top,
                height: 100,
                child: Container(key: const Key('content')),
              ),
            ],
          ),
        ),
      );

      // 1. Initial State: Visible (Opacity 1.0)
      // Expect RepaintBoundary -> ClipRect -> OverflowBox -> Content
      // Expect NO Opacity/IgnorePointer wrapping the content.
      
      final contentFinder = find.byKey(const Key('content'));
      expect(contentFinder, findsOneWidget);

      final repaintBoundaryFinder = find.ancestor(of: contentFinder, matching: find.byType(RepaintBoundary)).first;
      expect(repaintBoundaryFinder, findsOneWidget);

      // Verify NO Opacity with opacity=1.0 in ancestry chain up to PanelArea
      bool hasOpacity1 = false;
      tester.element(contentFinder).visitAncestorElements((element) {
        if (element.widget is Opacity) {
          final op = element.widget as Opacity;
          if (op.opacity == 1.0) {
            hasOpacity1 = true;
            return false;
          }
        }
        if (element.widget is PanelArea) return false;
        return true;
      });
      expect(hasOpacity1, isFalse, reason: 'Optimization Fail: Unnecessary Opacity(1.0) found.');

      // 2. Animate Hide
      final controller = PanelArea.of(tester.element(contentFinder));
      controller.setVisible(const PanelId('top'), false);
      await tester.pump(); 
      await tester.pump(const Duration(milliseconds: 50)); // Mid-animation

      // Expect Opacity < 1.0 to exist
      bool hasOpacityAnimating = false;
      tester.element(contentFinder).visitAncestorElements((element) {
        if (element.widget is Opacity) {
          final op = element.widget as Opacity;
          if (op.opacity < 1.0 && op.opacity > 0.0) {
            hasOpacityAnimating = true;
            return false;
          }
        }
        if (element.widget is PanelArea) return false;
        return true;
      });
      expect(hasOpacityAnimating, isTrue, reason: 'Animation Fail: Opacity widget should be present during animation.');
    });

    testWidgets('AnimatedHorizontalPanel: Removes Opacity/IgnorePointer when stable', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PanelArea(
            children: [
              InlinePanel(
                id: const PanelId('left'),
                anchor: PanelAnchor.left,
                width: 100,
                child: Container(key: const Key('content')),
              ),
            ],
          ),
        ),
      );

      final contentFinder = find.byKey(const Key('content'));
      
      // Verify RepaintBoundary (use .first to get the closest one, avoiding system boundaries)
      expect(find.ancestor(of: contentFinder, matching: find.byType(RepaintBoundary)).first, findsOneWidget);

      // Verify NO Opacity 1.0
      bool hasOpacity1 = false;
      tester.element(contentFinder).visitAncestorElements((element) {
        if (element.widget is Opacity) {
          final op = element.widget as Opacity;
          if (op.opacity == 1.0) {
            hasOpacity1 = true;
            return false;
          }
        }
        if (element.widget is PanelArea) return false;
        return true;
      });
      expect(hasOpacity1, isFalse, reason: 'Optimization Fail: Unnecessary Opacity(1.0) found.');
    });

    testWidgets('AnimatedHorizontalPanel: Rail is ignored when Expanded', (tester) async {
      // Regression test for "Ambiguous tap" issue.
      // When expanded, the Rail icon should exist (for tests to find) but be Ignored (IgnorePointer).
      
      await tester.pumpWidget(
        MaterialApp(
          home: PanelArea(
            children: [
              InlinePanel(
                id: const PanelId('left'),
                anchor: PanelAnchor.left,
                width: 100,
                icon: const Icon(Icons.chevron_left), // Used in Header AND Rail
                child: Container(),
              ),
            ],
          ),
        ),
      );

      // We expect 2 icons total.
      final iconFinder = find.byIcon(Icons.chevron_left);
      expect(iconFinder, findsNWidgets(2));

      // We want to tap "the icon".
      // If hit testing is working correctly, only ONE should be hit testable (the Header one).
      // The Rail one should be ignored.
      
      final hitTestableIcons = iconFinder.hitTestable();
      expect(hitTestableIcons, findsOneWidget, reason: 'Rail icon should be ignored when panel is expanded.');
      
      // Tapping should work without ambiguity exception
      await tester.tap(hitTestableIcons);
      await tester.pumpAndSettle();
    });

    testWidgets('AnimatedHorizontalPanel: Uses SingleChildScrollView for Layout Safety', (tester) async {
      // Regression test for Infinite Height / Overflow warnings.
      // We check that the widget tree contains SingleChildScrollView wrapping the content.
      
      await tester.pumpWidget(
        MaterialApp(
          home: PanelArea(
            children: [
              InlinePanel(
                id: const PanelId('left'),
                anchor: PanelAnchor.left,
                width: 100, // Fixed Width triggers the logic
                child: Container(key: const Key('content')),
              ),
            ],
          ),
        ),
      );

      final contentFinder = find.byKey(const Key('content'));
      
      // Look for SingleChildScrollView ancestor
      final scrollFinder = find.ancestor(of: contentFinder, matching: find.byType(SingleChildScrollView));
      expect(scrollFinder, findsOneWidget);
      
      final SingleChildScrollView scrollWidget = tester.widget(scrollFinder);
      expect(scrollWidget.scrollDirection, Axis.horizontal);
      expect(scrollWidget.physics, isA<NeverScrollableScrollPhysics>());
    });
  });
}
