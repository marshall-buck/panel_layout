import 'package:flutter/rendering.dart';

/// Abstract interface for layout operations, decoupling strategies from [MultiChildLayoutDelegate].
abstract class LayoutContext {
  /// Ask the child to update its layout within the limits given by the constraints.
  Size layoutChild(Object childId, BoxConstraints constraints);

  /// Position the child at the given offset.
  void positionChild(Object childId, Offset offset);

  /// True if a child with the given ID exists.
  bool hasChild(Object childId);
}
