import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:panel_layout/panel_layout.dart';

class VerticalSplitTab extends StatelessWidget {
  const VerticalSplitTab({super.key});

  @override
  Widget build(BuildContext context) {
    return PanelLayout(
      style: kAppPanelStyle,
      children: [
        // TOP PANEL: Header / Toolbar
        // 6. Non-resizable panel
        InlinePanel(
          id: const PanelId('header'),
          anchor: PanelAnchor.top,
          height: 60,
          resizable: false, // User cannot resize this
          title: 'TOOLBAR (FIXED)',
          // Add chevron_left to demonstrate rotation (Should point Down v when open, Up ^ when collapsed)
          icon: const Icon(Icons.chevron_left),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Icon(Icons.play_arrow, color: Colors.green),
              Icon(Icons.pause, color: Colors.orange),
              Icon(Icons.stop, color: Colors.red),
            ],
          ),
        ),

        // CENTER PANEL: Content
        const Center(child: Text('Main Content Area')),

        // BOTTOM PANEL: Terminal
        // Resizable
        InlinePanel(
          id: const PanelId('terminal'),
          anchor: PanelAnchor.bottom,
          height: 150,
          title: 'TERMINAL',
          clipContent: true,
          // Use a chevron. PanelToggleButton will rotate this:
          // - Open: Points Down (v)
          // - Collapsed: Points Up (^)
          // This assumes standard left-chevron input logic.
          icon: const Icon(Icons.chevron_left),
          child: Container(
            color: Colors.black,
            padding: const EdgeInsets.all(8),
            child: const Text(
              '> flutter run',
              style: TextStyle(
                color: Colors.greenAccent,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
