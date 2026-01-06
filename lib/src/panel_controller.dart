import 'package:flutter/widgets.dart';

import 'panel_data.dart';

/// Manages the state, configuration, and runtime behavior of a single layout panel.
///
/// The [PanelController] is the source of truth for a panel's:
/// - **Sizing**: How large it is ([PanelSizing]).
/// - **Visibility**: Whether it is shown, hidden, or collapsed.
/// - **Mode**: Whether it is inline or overlaid.
/// - **Visuals**: Styling attributes like borders and animations.
///
/// It extends [ChangeNotifier], allowing the UI to rebuild reactively when properties change.
class PanelController extends ChangeNotifier {
  /// Creates a new [PanelController] for the panel with the given [id].
  PanelController({
    required this.id,
    required PanelSizing sizing,
    required PanelMode mode,
    required PanelAnchor anchor,
    PanelId? anchorPanel,
    PanelConstraints constraints = const PanelConstraints(),
    PanelVisuals visuals = const PanelVisuals(),
    bool isCollapsed = false,
    bool isVisible = true,
    this.isResizable = true,
  }) : _sizing = sizing,
       _mode = mode,
       _anchor = anchor,
       _anchorPanel = anchorPanel,
       _constraints = constraints,
       _visuals = visuals,
       _isCollapsed = isCollapsed,
       _isVisible = isVisible;

  /// The unique identifier for this panel.
  final PanelId id;

  /// Whether this panel allows user resizing via drag handles.
  final bool isResizable;

  /// A stable handle for this panel's geometry in the render tree.
  /// Used as a target for [CompositedTransformFollower] by panels anchored to this one.
  final LayerLink layerLink = LayerLink();

  PanelSizing _sizing;
  PanelMode _mode;
  final PanelAnchor _anchor;
  final PanelId? _anchorPanel;
  final PanelConstraints _constraints;
  PanelVisuals _visuals;

  bool _isCollapsed;
  bool _isVisible;

  /// The current sizing strategy of the panel.
  PanelSizing get sizing => _sizing;

  /// The positioning mode of the panel.
  PanelMode get mode => _mode;

  /// The edge of the container to which this panel is anchored.
  PanelAnchor get anchor => _anchor;

  /// The ID of the panel to which this panel is anchored (if any).
  ///
  /// If null, the panel is anchored to the layout container's edge.
  PanelId? get anchorPanel => _anchorPanel;

  /// The constraint boundaries for this panel.
  PanelConstraints get constraints => _constraints;

  /// The visual styling configuration for the panel.
  PanelVisuals get visuals => _visuals;

  /// Whether the panel is currently in its collapsed state.
  bool get isCollapsed => _isCollapsed;

  /// Whether the panel is currently visible in the layout.
  bool get isVisible => _isVisible;

  /// Calculates the effective logical pixel size or flex weight for rendering.
  double get effectiveSize {
    if (!_isVisible) return 0;
    if (_isCollapsed) return _constraints.collapsedSize;
    if (_sizing is FixedSizing) {
      return (_sizing as FixedSizing).size;
    }
    if (_sizing is FlexibleSizing) {
      return (_sizing as FlexibleSizing).weight;
    }
    return -1;
  }

  // --- Actions ---

  /// Updates the size of the panel.
  void resize(double newSize) {
    if (_sizing is ContentSizing) return;
    if (!isResizable) return;

    if (_sizing is FixedSizing) {
      final clamped = newSize.clamp(_constraints.minSize, _constraints.maxSize);
      if ((_sizing as FixedSizing).size != clamped) {
        _sizing = FixedSizing(clamped);
        notifyListeners();
      }
    } else if (_sizing is FlexibleSizing) {
      final newWeight = newSize > 0 ? newSize : 0.0;
      if ((_sizing as FlexibleSizing).weight != newWeight) {
        _sizing = FlexibleSizing(newWeight);
        notifyListeners();
      }
    }
  }

  /// Toggles the panel between expanded and collapsed states.
  void toggle() {
    _isCollapsed = !_isCollapsed;
    notifyListeners();
  }

  /// Sets the visibility of the panel.
  void setVisible({required bool visible}) {
    if (_isVisible != visible) {
      _isVisible = visible;
      notifyListeners();
    }
  }

  /// Updates the visual appearance configuration.
  void setVisuals(PanelVisuals visuals) {
    _visuals = visuals;
    notifyListeners();
  }

  /// Changes the layout mode of the panel.
  void setMode(PanelMode mode) {
    if (_mode != mode) {
      _mode = mode;
      notifyListeners();
    }
  }
}
