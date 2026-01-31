import 'package:flutter/widgets.dart';
import '../panels/inline_panel.dart';

/// An internal wrapper that adapts standard [Widget]s into the panel system.
///
/// This class is used automatically by [PanelArea] when it encounters
/// a child that is not a [BasePanel].
///
/// Behavior:
/// - Always has a layout weight of 1.0 (fills available space).
/// - Has no header, decoration, or built-in padding.
/// - Does not initiate resizing (passive).
class InternalLayoutAdapter extends InlinePanel {
  const InternalLayoutAdapter({
    required super.id,
    required super.child,
    super.key,
  }) : super(
         initialCollapsed: false,
         headerHeight: 0.0,
         panelBoxDecoration: null,
         resizable: false,
       );

  /// Standard widgets wrapped in this adapter always have a layout weight of 1.0.
  double get layoutWeight => 1.0;

  @override
  Widget build(BuildContext context) {
    // Render the child directly, bypassing BasePanel's header/decoration logic.
    return child;
  }
}
