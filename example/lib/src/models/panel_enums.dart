import 'package:flutter/widgets.dart';

/// Defines which edge a panel is logically attached to.
///
/// This determines:
/// 1. The direction of resizing (e.g., [left] panels resize horizontally).
/// 2. The alignment of overlay panels (e.g., [right] overlays align to the right).
/// 3. The scroll direction if the content overflows.
enum PanelAnchor { left, right, top, bottom }
