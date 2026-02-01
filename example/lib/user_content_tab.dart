import 'package:flutter/material.dart';
import 'package:flutter_panels/flutter_panels.dart';
import 'main.dart'; // To access kAppPanelStyle

// -----------------------------------------------------------------------------
// Tab 5: User Content
// Demonstrates: Standard Widgets as panels (filling available space)
// -----------------------------------------------------------------------------
class UserContentTab extends StatefulWidget {
  const UserContentTab({super.key});

  @override
  State<UserContentTab> createState() => _UserContentTabState();
}

class _UserContentTabState extends State<UserContentTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // ROOT LAYOUT (Vertical)
    // 1. Top Panel
    // 2. Main Content Area (Nested Horizontal Layout)
    return PanelArea(
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
        // We can use a raw Widget or just an Widget (layoutWeight: 1) to hold the nested layout.
        // Standard widgets automatically fill remaining space without props.
        _NestedLayoutContainer(
          content: PanelArea(
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
              const EditorPanel(),

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
              const PreviewPanel(),
            ],
          ),
        ),
      ],
    );
  }
}

// A simple wrapper to allow the nested layout to fill the vertical space
class _NestedLayoutContainer extends StatelessWidget {
  final Widget content;
  const _NestedLayoutContainer({required this.content});

  @override
  Widget build(BuildContext context) {
    return content;
  }
}

// Custom implementations
class EditorPanel extends StatelessWidget {
  const EditorPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.blueGrey[50],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.edit_note, size: 48, color: Colors.blueGrey),
            Text('Editor Area'),
            Text('(Standard Widget)', style: TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class PreviewPanel extends StatelessWidget {
  const PreviewPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.amber[50],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.visibility, size: 48, color: Colors.amber),
            Text('Preview Area'),
            Text('(Standard Widget)', style: TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
