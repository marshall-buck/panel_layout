import 'package:flutter/widgets.dart';

import '../models/panel_enums.dart';
import '../models/panel_id.dart';

/// Exception thrown when [PanelLayout] detects conflicting panel anchors.
///
/// This occurs when a single [PanelLayout] contains [InlinePanel]s that imply different
/// layout axes (e.g., mixing [PanelAnchor.top] (vertical) and [PanelAnchor.left] (horizontal)).
class AnchorException implements Exception {
  final PanelId firstPanelId;
  final Axis firstAxis;
  final PanelId conflictingPanelId;
  final Axis conflictingAxis;

  const AnchorException({
    required this.firstPanelId,
    required this.firstAxis,
    required this.conflictingPanelId,
    required this.conflictingAxis,
  });

  @override
  String toString() {
    return 'AnchorException: PanelLayout contains InlinePanels with conflicting axes.\n'
        ' - Panel "${firstPanelId.value}" established axis: $firstAxis\n'
        ' - Panel "${conflictingPanelId.value}" conflicts with axis: $conflictingAxis\n'
        'InlinePanels in a single PanelLayout must share the same axis (Vertical or Horizontal).';
  }
}
