import 'package:panel_layout/src/widgets/internal/internal_layout_adapter.dart';

class TestContentPanel extends InternalLayoutAdapter {
  const TestContentPanel({
    required super.id,
    required super.child,
    this.flexOverride = 1.0,
    super.key,
  });

  final double flexOverride;

  @override
  double get flex => flexOverride;
}
