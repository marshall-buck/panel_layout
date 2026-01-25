import 'package:flutter/material.dart';
import 'package:panel_layout/panel_layout.dart';
import 'main.dart'; // To access kAppPanelStyle

// -----------------------------------------------------------------------------
// Tab 5: User Content
// Demonstrates: Extending UserContent for specialized, property-free panels
// -----------------------------------------------------------------------------
class UserContentTab extends StatelessWidget {
  const UserContentTab({super.key});

  @override
  Widget build(BuildContext context) {
    // ROOT LAYOUT (Vertical)
    // 1. Top Panel
    // 2. Main Content Area (Nested Horizontal Layout)
    return PanelLayout(
      style: kAppPanelStyle,
      children: [
        // 1. Top Panel (Resizable)
        InlinePanel(
          id: const PanelId('top_bar'),
          anchor: PanelAnchor.top,
          height: 80,
          minSize: 50,
          maxSize: 150,
          title: 'TOP BAR',
          icon: const Icon(Icons.chevron_left), // Rotates to point up/down
          child: const Center(child: Text('Global Header (Resizable)')),
        ),

        // 2. Main Content Area (Implicit Flex: 1)
        // We can use a raw UserContent or just an InlinePanel(flex: 1) to hold the nested layout.
        // Let's use UserContent to handle the "fill remaining space" logic cleanly without props.
        _NestedLayoutContainer(
          id: const PanelId('main_area'),
          content: PanelLayout(
            style: kAppPanelStyle,
            children: [
              // A. Left Panel
              InlinePanel(
                id: const PanelId('left_nav'),
                anchor: PanelAnchor.left,
                width: 200,
                title: 'NAV',
                icon: const Icon(Icons.chevron_left),
                child: const Center(child: Text('Left Navigation')),
              ),

              // B. User Content 1 (Editor)
              EditorPanel(id: const PanelId('editor_area')),

              // C. Tools Panel (Anchored Right)
              // This sits between Editor and Preview.
              // Logic: It resizes against Editor (Left) and Preview (Right).
              InlinePanel(
                id: const PanelId('tools'),
                anchor: PanelAnchor.right,
                width: 200,
                title: 'TOOLS',
                icon: const Icon(Icons.build),
                child: const Center(
                  child: Text('Tool Palette\n(Anchored Right)'),
                ),
              ),

              // D. User Content 2 (Preview)
              PreviewPanel(id: const PanelId('preview_area')),
            ],
          ),
        ),
      ],
    );
  }
}

// A simple wrapper to allow the nested layout to fill the vertical space
class _NestedLayoutContainer extends UserContent {
  final Widget content;
  const _NestedLayoutContainer({required super.id, required this.content});

  @override
  Widget buildContent(BuildContext context) {
    return content;
  }
}

// Custom UserContent implementations
class EditorPanel extends UserContent {
  const EditorPanel({super.key, required super.id});

  @override
  Widget buildContent(BuildContext context) {
    return Container(
      color: Colors.blueGrey[50],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_note, size: 48, color: Colors.blueGrey),
            Text('Editor Area'),
            Text('(UserContent)', style: TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class PreviewPanel extends UserContent {
  const PreviewPanel({super.key, required super.id});

  @override
  Widget buildContent(BuildContext context) {
    return Container(
      color: Colors.amber[50],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.visibility, size: 48, color: Colors.amber),
            Text('Preview Area'),
            Text('(UserContent)', style: TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
