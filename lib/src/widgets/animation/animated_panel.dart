import 'package:flutter/widgets.dart';
import 'package:meta/meta.dart';
import '../../models/panel_enums.dart';
import '../../state/panel_runtime_state.dart';
import '../../state/panel_data_scope.dart';
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
    required this.initialState,
    required this.stateNotifier,
    required this.visibilityAnimation,
    required this.collapseAnimation,
  });

  /// The static configuration for this panel (id, min/max sizes, initial state).
  final BasePanel config;

  /// The dynamic runtime state (current size, visibility status).
  final PanelRuntimeState initialState;
  
  /// The notifier for state changes.
  final ValueNotifier<PanelRuntimeState> stateNotifier;

  /// The visibility animation controller.
  final Animation<double> visibilityAnimation;

  /// The collapse animation controller.
  final Animation<double> collapseAnimation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([visibilityAnimation, collapseAnimation, stateNotifier]),
      builder: (context, _) {
        final state = stateNotifier.value;
        final factor = visibilityAnimation.value;

        // Optimization: Don't build anything if the panel is fully hidden.
        if (factor <= 0 && !state.visible) {
          return const SizedBox.shrink();
        }

        Widget child;
        // Delegate based on anchor direction.
        // Top/Bottom -> Vertical Animation (Height)
        if (config.anchor == PanelAnchor.top ||
            config.anchor == PanelAnchor.bottom) {
          child = AnimatedVerticalPanel(
            config: config,
            state: state,
            visibilityAnimation: visibilityAnimation,
            collapseAnimation: collapseAnimation,
          );
        } else {
          // Left/Right (or null) -> Horizontal Animation (Width)
          child = AnimatedHorizontalPanel(
            config: config,
            state: state,
            visibilityAnimation: visibilityAnimation,
            collapseAnimation: collapseAnimation,
          );
        }
        
        return PanelDataScope(
            state: state,
            config: config,
            child: child,
        );
      },
    );
  }
}
