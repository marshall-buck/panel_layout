import 'package:flutter_panels/src/widgets/internal/internal_layout_adapter.dart';

class TestContentPanel extends InternalLayoutAdapter {
  const TestContentPanel({
    required super.id,
    required super.child,
    this.layoutWeightOverride = 1.0,
    super.key,
  });

  final double layoutWeightOverride;

  @override
  double get layoutWeight => layoutWeightOverride;
}
