import 'package:flutter/widgets.dart';

import 'panel_layout_controller.dart';
import 'panel_scope.dart';

/// The root widget for the panel layout system.
///
/// This widget creates, manages, and disposes a [PanelLayoutController].
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
  const PanelLayout({required this.builder, super.key});

  /// The builder for the content of the layout scope.
  ///
  /// Exposes the [PanelLayoutController] so it can be initialized immediately.
  final Widget Function(BuildContext context, PanelLayoutController controller)
  builder;

  /// Retrieves the [PanelLayoutController] from the nearest ancestor [PanelLayout].
  ///
  /// If [listen] is true (default), the context will rebuild if the
  /// *controller instance* changes (rare).
  static PanelLayoutController of(BuildContext context, {bool listen = true}) {
    return PanelScope.of(context, listen: listen);
  }

  @override
  State<PanelLayout> createState() => _PanelLayoutState();
}

class _PanelLayoutState extends State<PanelLayout> {
  late final PanelLayoutController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PanelLayoutController();
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
