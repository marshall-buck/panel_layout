import 'package:flutter/widgets.dart';
import 'inline_panel.dart';

/// An abstract base class for user content panels.
///
/// Users should extend this class to define content regions that automatically
/// fill the available space ([flex] = 1.0) and participate in the layout
/// without headers or default decorations.
///
/// Adjacent [UserContent] panels do not have resize handles between them;
/// they share the available space equally (or based on internal flex behavior if customized).
abstract class UserContent extends InlinePanel {
  const UserContent({required super.id, super.key})
    : super(
        flex: 1.0,
        headerHeight: 0.0,
        panelBoxDecoration: null,
        child: const SizedBox(), // Placeholder, build is overridden
      );

  @override
  Widget build(BuildContext context) {
    return buildContent(context);
  }

  /// Builds the content of this panel.
  Widget buildContent(BuildContext context);
}
