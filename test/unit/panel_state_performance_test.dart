import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_panels/flutter_panels.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Rendering Optimization: Opacity widget is REMOVED when panel is fully visible', (tester) async {
    // 1. Setup a standard panel area
    await tester.pumpWidget(
      MaterialApp(
        home: PanelArea(
          children: [
            InlinePanel(
              id: const PanelId('test'),
              width: 200,
              child: Container(color: Colors.red),
            ),
            Container(color: Colors.blue), // Content
          ],
        ),
      ),
    );

    // 2. Initial State: Panel is Visible (1.0 opacity).
    // Expect NO Opacity widget wrapping the panel content.
    // The hierarchy in AnimatedHorizontalPanel is complex, so we look for Opacity widgets.
    // There might be Opacity widgets for the "Rail" (which is hidden/0.0), 
    // but the Main Content should NOT be wrapped in Opacity(1.0).

    // Let's find the content container (Red).
    final contentFinder = find.byWidgetPredicate((w) => w is Container && w.color == Colors.red);
    expect(contentFinder, findsOneWidget);

    // Check ancestors.
    // If optimization is working, there should be NO Opacity widget with opacity 1.0 in the ancestry chain
    // of the content (up to the AnimatedPanel).
    
    // Helper to check ancestry
    bool hasOpacity1Wrapper(Finder childFinder) {
      final element = tester.element(childFinder);
      bool found = false;
      element.visitAncestorElements((ancestor) {
        if (ancestor.widget is Opacity) {
          final op = ancestor.widget as Opacity;
          if (op.opacity == 1.0) {
            found = true;
            return false; // Stop visiting
          }
        }
        if (ancestor.widget is PanelArea) {
          return false; // Stop at root
        }
        return true;
      });
      return found;
    }

    expect(hasOpacity1Wrapper(contentFinder), isFalse, 
      reason: 'Optimization Failed: Content is wrapped in unnecessary Opacity(1.0) widget.');

  });
}