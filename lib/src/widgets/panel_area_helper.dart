import 'package:flutter/widgets.dart';

class PaintItem {
  final Object id;
  final Widget widget;
  final int zIndex;
  final bool isHandle;
  final int originalIndex;

  PaintItem({
    required this.id,
    required this.widget,
    required this.zIndex,
    required this.isHandle,
    required this.originalIndex,
  });
}