import 'package:flutter/material.dart';
import 'package:flutter_panels/flutter_panels.dart';

class ScopedTab extends StatefulWidget {
  const ScopedTab({super.key});

  @override
  State<ScopedTab> createState() => _ScopedTabState();
}

class _ScopedTabState extends State<ScopedTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return PanelArea(
      // Outer Layout Style: Dark Theme
      style: PanelStyle(
        headerDecoration: const BoxDecoration(
          color: Color(0xFF212121),
          border: Border(bottom: BorderSide(color: Colors.black, width: 2)),
        ),
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
        iconColor: Colors.white,
        panelBoxDecoration: const BoxDecoration(color: Color(0xFF303030)),
      ),
      children: [
        // Left Panel (Outer Scope)
        InlinePanel(
          id: const PanelId('outer_left'),
          anchor: PanelAnchor.left,
          width: 200,
          title: 'OUTER SCOPE',
          icon: const Icon(Icons.chevron_left),
          child: const Center(
            child: Text('Dark Theme', style: TextStyle(color: Colors.white70)),
          ),
        ),

        // Center Panel (Contains Nested Scope)
        PanelArea(
          // Inner Layout Style: Light/Blue Theme
          // This overrides the outer style for all children in this subtree.
          style: PanelStyle(
            headerDecoration: BoxDecoration(
              color: Colors.blue[100],
              border: Border(bottom: BorderSide(color: Colors.blue[300]!)),
            ),
            titleTextStyle: TextStyle(
              color: Colors.blue[900],
              fontWeight: FontWeight.w600,
            ),
            iconColor: Colors.blue[900],
            panelBoxDecoration: const BoxDecoration(color: Colors.white),
          ),
          children: [
            InlinePanel(
              id: const PanelId('inner_top'),
              anchor: PanelAnchor.top,
              height: 100,
              title: 'INNER SCOPE (TOP)',
              icon: const Icon(Icons.chevron_left),
              child: const Center(child: Text('Light/Blue Theme')),
            ),
            const Center(child: Text('Content Area')),
          ],
        ),
      ],
    );
  }
}
