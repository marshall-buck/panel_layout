import 'package:flutter_test/flutter_test.dart';
import 'package:panel_layout/panel_layout.dart';

void main() {
  group('Models Unit Tests', () {
    test('PanelRuntimeState.copyWith works', () {
      final state = PanelRuntimeState(
        size: 100,
        visible: true,
        collapsed: false,
      );
      final copy = state.copyWith(size: 200, visible: false);

      expect(copy.size, 200);
      expect(copy.visible, false);
      expect(copy.collapsed, false);
    });

    test('PanelId equality', () {
      const id1 = PanelId('a');
      const id2 = PanelId('a');
      const id3 = PanelId('b');

      expect(id1, id2);
      expect(id1, isNot(id3));
      expect(id1.hashCode, id2.hashCode);
    });

    test('ResizeHandleThemeData equality', () {
      const t1 = ResizeHandleThemeData(width: 10);
      const t2 = ResizeHandleThemeData(width: 10);
      const t3 = ResizeHandleThemeData(width: 20);

      expect(t1, t2);
      expect(t1, isNot(t3));
    });
  });
}
