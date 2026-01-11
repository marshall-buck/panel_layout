import 'package:flutter/widgets.dart';

import '../models/panel_id.dart';
import '../models/panel_sizing.dart';
import '../models/panel_enums.dart';
import '../models/panel_constraints.dart';
import '../models/panel_visuals.dart';

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
    required this.builder,
    required PanelSizing sizing,
    required PanelMode mode,
    required PanelAnchor anchor,
    PanelId? anchorPanel,
    AlignmentGeometry? alignment,
    LayerLink? anchorLink,
    CrossAxisAlignment? crossAxisAlignment,
    PanelConstraints constraints = const PanelConstraints(),
    PanelVisuals visuals = const PanelVisuals(),
    bool isCollapsed = false,
    bool isVisible = true,
    this.isResizable = true,
    int zIndex = 0,
  }) : _sizing = sizing,
       _mode = mode,
       _anchor = anchor,
       _anchorPanel = anchorPanel,
       _alignment = alignment,
       _anchorLink = anchorLink,
       _crossAxisAlignment = crossAxisAlignment,
       _constraints = constraints,
       _visuals = visuals,
       _isCollapsed = isCollapsed,
       _isVisible = isVisible,
       _zIndex = zIndex;

  /// The unique identifier for this panel.
  final PanelId id;

  /// The builder function that creates the widget tree for this panel.
  final Widget Function(BuildContext context, PanelController controller)
  builder;

  /// Whether this panel allows user resizing via drag handles.
  final bool isResizable;

  /// A stable handle for this panel's geometry in the render tree.
  /// Used as a target for [CompositedTransformFollower] by panels anchored to this one.
  final LayerLink layerLink = LayerLink();

  PanelSizing _sizing;
  PanelMode _mode;
  final PanelAnchor _anchor;
  final PanelId? _anchorPanel;
  final AlignmentGeometry? _alignment;
  final LayerLink? _anchorLink;
  final CrossAxisAlignment? _crossAxisAlignment;
  final PanelConstraints _constraints;
  PanelVisuals _visuals;

  bool _isCollapsed;
  bool _isVisible;
  int _zIndex;

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

  /// Custom alignment for the panel, overriding the default anchor-based alignment.
  AlignmentGeometry? get alignment => _alignment;

  /// An external LayerLink to anchor this panel to, overriding [anchorPanel].
  LayerLink? get anchorLink => _anchorLink;

  /// Cross-axis alignment for the panel content.
  /// If null, defaults to [CrossAxisAlignment.stretch].
  CrossAxisAlignment? get crossAxisAlignment => _crossAxisAlignment;

  /// The constraint boundaries for this panel.
  PanelConstraints get constraints => _constraints;

  /// The visual styling configuration for the panel.
  PanelVisuals get visuals => _visuals;

  /// Whether the panel is currently in its collapsed state.
  bool get isCollapsed => _isCollapsed;

  /// Whether the panel is currently visible in the layout.
  bool get isVisible => _isVisible;

  /// The painting order of the panel. Higher values are painted on top.
  int get zIndex => _zIndex;

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

  /// Updates the z-index of the panel.
  void setZIndex(int zIndex) {
    if (_zIndex != zIndex) {
      _zIndex = zIndex;
      notifyListeners();
    }
  }
}
