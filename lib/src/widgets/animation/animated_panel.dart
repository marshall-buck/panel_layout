import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import '../../models/panel_enums.dart';
import '../../state/panel_runtime_state.dart';
import '../panels/base_panel.dart';
import 'animated_vertical_panel.dart';
import 'animated_horizontal_panel.dart';

/// An internal wrapper widget that acts as a dispatcher for panel animations.
///
/// It connects a panel's static [config] ([BasePanel]) with its dynamic [state]
/// ([PanelRuntimeState]), delegating the actual rendering to specialized animators:
/// * [AnimatedVerticalPanel] for Top/Bottom panels (Height animation).
/// * [AnimatedHorizontalPanel] for Left/Right panels (Width animation).
///
/// This separation ensures that the physics and layout logic for each direction
/// can be optimized independently (e.g. persistent headers for vertical panels
/// vs. cross-fading rails for horizontal panels).
@internal
class AnimatedPanel extends StatelessWidget {
  const AnimatedPanel({
    super.key,
    required this.config,
    required this.state,
    required this.factor,
    required this.collapseFactor,
  });

  /// The static configuration for this panel (id, min/max sizes, initial state).
  final BasePanel config;

  /// The dynamic runtime state (current size, visibility status).
  final PanelRuntimeState state;

  /// The visibility animation factor, ranging from 0.0 (hidden) to 1.0 (fully visible).
  final double factor;

  /// The collapse animation factor, ranging from 0.0 (fully expanded) to 1.0 (fully collapsed/rail).
  final double collapseFactor;

  @override
  Widget build(BuildContext context) {
    // Optimization: Don't build anything if the panel is fully hidden.
    if (factor <= 0 && !state.visible) {
      return const SizedBox.shrink();
    }

    // Delegate based on anchor direction.
    // Top/Bottom -> Vertical Animation (Height)
    if (config.anchor == PanelAnchor.top ||
        config.anchor == PanelAnchor.bottom) {
      return AnimatedVerticalPanel(
        config: config,
        state: state,
        factor: factor,
        collapseFactor: collapseFactor,
      );
    }

    // Left/Right (or null) -> Horizontal Animation (Width)
    return AnimatedHorizontalPanel(
      config: config,
      state: state,
      factor: factor,
      collapseFactor: collapseFactor,
    );
  }
}
