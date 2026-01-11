import 'package:flutter/widgets.dart';

import '../models/panel_id.dart';
import '../models/panel_enums.dart';
import '../state/panel_runtime_state.dart';
import '../state/panel_scope.dart';
import '../state/panel_data_scope.dart';
import '../layout/layout_data.dart';
import '../layout/panel_layout_delegate.dart';
import '../controllers/panel_layout_controller.dart';
import 'base_panel.dart';
import 'panel_resize_handle.dart';

/// The declarative orchestrator for the panel layout system.
///
/// [PanelLayout] manages a list of [BasePanel] children. It tracks their
/// ephemeral state (like dragged size or collapse state) and calculates
/// their layout using a custom delegate.
class PanelLayout extends StatefulWidget {
  /// Creates a declarative panel layout.
  const PanelLayout({
    required this.children,
    this.controller,
    this.axis = Axis.horizontal,
    super.key,
  });

  /// The list of declarative panel configurations. 
  /// 
  /// These widgets should extend [BasePanel].
  final List<BasePanel> children;

  /// An optional controller to manipulate panel state programmatically.
  final PanelLayoutController? controller;

  /// The main axis of the layout.
  final Axis axis;

  /// Retrieves the [PanelLayoutController] from the closest [PanelScope] ancestor.
  static PanelLayoutController of(BuildContext context) {
    return PanelScope.of(context);
  }

  @override
  State<PanelLayout> createState() => _PanelLayoutState();
}

class _PanelLayoutState extends State<PanelLayout> implements PanelLayoutStateInterface {
  /// Internal state for each panel, keyed by ID.
  final Map<PanelId, PanelRuntimeState> _panelStates = {};

  PanelLayoutController? _internalController;
  PanelLayoutController get _effectiveController => widget.controller ?? _internalController!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _internalController = PanelLayoutController();
    }
    _reconcileState();
    _effectiveController.attach(this);
  }

  @override
  void didUpdateWidget(PanelLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (oldWidget.controller == null) {
        _internalController?.detach();
        _internalController = null;
      } else {
        oldWidget.controller!.detach();
      }

      if (widget.controller == null) {
        _internalController = PanelLayoutController();
      }
      _effectiveController.attach(this);
    }
    _reconcileState();
  }

  @override
  void dispose() {
    _effectiveController.detach();
    _internalController?.dispose(); 
    super.dispose();
  }

  // --- Interface Implementation ---

  @override
  void toggleVisible(PanelId id) {
    if (_panelStates.containsKey(id)) {
      setState(() {
        _panelStates[id]!.visible = !_panelStates[id]!.visible;
      });
    }
  }

  @override
  void toggleCollapsed(PanelId id) {
    if (_panelStates.containsKey(id)) {
      setState(() {
        _panelStates[id]!.collapsed = !_panelStates[id]!.collapsed;
      });
    }
  }

  @override
  void setVisible(PanelId id, bool visible) {
    if (_panelStates.containsKey(id)) {
      setState(() {
        _panelStates[id]!.visible = visible;
      });
    }
  }

  @override
  void setCollapsed(PanelId id, bool collapsed) {
    if (_panelStates.containsKey(id)) {
      setState(() {
        _panelStates[id]!.collapsed = collapsed;
      });
    }
  }

  void _reconcileState() {
    final currentIds = widget.children.map((p) => p.id).toSet();
    
    // 1. Remove state for panels that are gone
    _panelStates.removeWhere((id, _) => !currentIds.contains(id));

    // 2. Initialize or Update state for active panels
    for (final panel in widget.children) {
      if (!_panelStates.containsKey(panel.id)) {
        // Initialize new panel state
        _panelStates[panel.id] = PanelRuntimeState(
          size: _getInitialSize(panel),
          visible: panel.initialVisible,
          collapsed: panel.initialCollapsed,
        );
      }
    }
  }

  double _getInitialSize(BasePanel panel) {
    if (panel.flex != null) return panel.flex!;
    if (panel.width != null) return panel.width!;
    if (panel.height != null) return panel.height!;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    // Combine Config + State into LayoutData
    final layoutData = widget.children.map((config) {
      return PanelLayoutData(
        config: config,
        state: _panelStates[config.id]!,
      );
    }).toList();

    // Identify needed handles
    final dockedPanels = layoutData
        .where((d) => d.config.mode == PanelMode.inline)
        .toList(); 
        
    final children = <Widget>[];

    // Add Panels
    for (final panel in widget.children) {
      children.add(
        LayoutId(
          id: panel.id,
          child: PanelDataScope(
            state: _panelStates[panel.id]!,
            child: panel,
          ),
        ),
      );
    }

    // Add Handles
    for (var i = 0; i < dockedPanels.length - 1; i++) {
      final prev = dockedPanels[i];
      final next = dockedPanels[i+1];
      
      if (!prev.state.visible || !next.state.visible) continue;
      if (prev.state.collapsed && next.state.collapsed) continue;
      
      final handleId = HandleLayoutId(prev.config.id, next.config.id);
      
      children.add(
        LayoutId(
          id: handleId,
          child: PanelResizeHandle(
            axis: widget.axis == Axis.horizontal ? Axis.vertical : Axis.horizontal,
            onDragUpdate: (delta) => _handleResize(delta, prev, next),
          ),
        ),
      );
    }

    return PanelScope(
      controller: _effectiveController,
      child: CustomMultiChildLayout(
        delegate: PanelLayoutDelegate(
          panels: layoutData,
          axis: widget.axis,
          textDirection: Directionality.of(context),
        ),
        children: children,
      ),
    );
  }

  void _handleResize(double delta, PanelLayoutData prev, PanelLayoutData next) {
    // Update State
    setState(() {
      // 1. Resize Prev (if Fixed)
      if (prev.config.flex == null && prev.config.resizable) {
        final newSize = (prev.state.size + delta).clamp(
          prev.config.minSize ?? 0.0,
          prev.config.maxSize ?? double.infinity,
        );
        prev.state.size = newSize;
        return;
      }
      
      // 2. Resize Next (if Fixed) - Moving handle right shrinks next?
      // No, moving handle right increases Prev.
      // If Prev is Flexible, and Next is Fixed:
      if (next.config.flex == null && next.config.resizable) {
         final newSize = (next.state.size - delta).clamp(
          next.config.minSize ?? 0.0,
          next.config.maxSize ?? double.infinity,
        );
        next.state.size = newSize;
        return;
      }
      
      // 3. Flex/Flex
      // Distribute weights
    });
  }
}
