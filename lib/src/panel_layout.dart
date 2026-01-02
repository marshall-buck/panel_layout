import 'package:flutter/widgets.dart';

import 'layout_controller.dart';
import 'panel_scope.dart';

/// The root widget for the panel layout system.
///
/// This widget creates, manages, and disposes a [LayoutController].
/// It must be placed above any [PanelArea] or widget that needs to access
/// the layout system.
///
/// Usage:
/// ```dart
/// PanelLayout(
///   builder: (context, controller) {
///     // Initialize panels here if needed
///     return MaterialApp(home: ...);
///   },
/// )
/// ```
class PanelLayout extends StatefulWidget {
  /// Creates a [PanelLayout].
  ///
  /// [builder]: A builder that provides the child widget and the created controller.
  const PanelLayout({
    required this.builder,
    super.key,
  });

  /// The builder for the content of the layout scope.
  ///
  /// Exposes the [LayoutController] so it can be initialized immediately.
  final Widget Function(BuildContext context, LayoutController controller) builder;

  /// Retrieves the [LayoutController] from the nearest ancestor [PanelLayout].
  ///
  /// If [listen] is true (default), the context will rebuild if the
  /// *controller instance* changes (rare).
  static LayoutController of(BuildContext context, {bool listen = true}) {
    return PanelScope.of(context, listen: listen);
  }

  @override
  State<PanelLayout> createState() => _PanelLayoutState();
}

class _PanelLayoutState extends State<PanelLayout> {
  late final LayoutController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LayoutController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PanelScope(
      controller: _controller,
      child: Builder(
        builder: (context) => widget.builder(context, _controller),
      ),
    );
  }
}
