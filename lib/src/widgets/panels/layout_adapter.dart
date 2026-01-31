import 'package:flutter/widgets.dart';

/// A mixin to mark a standard [Widget] as a participant in a [PanelArea].
///
/// While any [Widget] can be added to a [PanelArea], using this mixin
/// allows for future extensibility and clearer intent.
///
/// Widgets using this mixin (or standard widgets wrapped internally)
/// act as "flexible fillers" in the layout:
/// - They automatically fill available space (default flex = 1.0).
/// - They do not have headers or decorations by default.
/// - They do not have resize handles between themselves (only when adjacent to an [InlinePanel]).
mixin LayoutAdapter on Widget {}
