import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/panel_layout.dart';

void main() {
  group('PanelId', () {
    test('equality and hashCode', () {
      const id1 = PanelId('test');
      const id2 = PanelId('test');
      const id3 = PanelId('other');

      expect(id1, equals(id2));
      expect(id1.hashCode, equals(id2.hashCode));
      expect(id1, isNot(equals(id3)));
    });

    test('toString', () {
      expect(const PanelId('test').toString(), 'PanelId(test)');
    });
  });

  group('PanelSizing', () {
    test('FixedSizing stores size', () {
      const sizing = FixedSizing(100.0);
      expect(sizing.size, 100.0);
    });

    test('FlexibleSizing stores weight', () {
      const sizing = FlexibleSizing(2.0);
      expect(sizing.weight, 2.0);
    });

    test('ContentSizing is constant', () {
      const sizing1 = ContentSizing();
      const sizing2 = ContentSizing();
      expect(sizing1, equals(sizing2));
    });
  });

  group('PanelConstraints', () {
    test('defaults', () {
      const constraints = PanelConstraints();
      expect(constraints.minSize, 0.0);
      expect(constraints.maxSize, double.infinity);
      expect(constraints.collapsedSize, 48.0);
    });

    test('custom values', () {
      const constraints = PanelConstraints(
        minSize: 50.0,
        maxSize: 200.0,
        collapsedSize: 30.0,
      );
      expect(constraints.minSize, 50.0);
      expect(constraints.maxSize, 200.0);
      expect(constraints.collapsedSize, 30.0);
    });
  });

  group('PanelVisuals', () {
    test('defaults', () {
      const visuals = PanelVisuals();
      expect(visuals.animationDuration, const Duration(milliseconds: 300));
      expect(visuals.animationCurve, Curves.easeOutExpo);
    });

    test('copyWith', () {
      const visuals = PanelVisuals();
      final newVisuals = visuals.copyWith(
        animationDuration: const Duration(seconds: 1),
        animationCurve: Curves.linear,
      );

      expect(newVisuals.animationDuration, const Duration(seconds: 1));
      expect(newVisuals.animationCurve, Curves.linear);

      // Verify original is unchanged
      expect(visuals.animationDuration, const Duration(milliseconds: 300));
    });

    test('copyWith with nulls keeps original', () {
      const visuals = PanelVisuals(animationDuration: Duration(seconds: 1));
      final sameVisuals = visuals.copyWith();

      expect(sameVisuals.animationDuration, const Duration(seconds: 1));
      expect(sameVisuals.animationCurve, visuals.animationCurve);
    });
  });
}
