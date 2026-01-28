import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:panel_layout/panel_layout.dart';

class ClassicIdeTab extends StatefulWidget {
  const ClassicIdeTab({super.key});

  @override
  State<ClassicIdeTab> createState() => _ClassicIdeTabState();
}

class _ClassicIdeTabState extends State<ClassicIdeTab> {
  final _controller = PanelLayoutController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PanelLayout(
      controller: _controller,
      style: kAppPanelStyle, // Apply global config
      children: [
        // LEFT PANEL: Explorer
        // Standard usage. Inline, resizable.
        InlinePanel(
          id: const PanelId('explorer'),
          anchor: PanelAnchor.left,
          width: 250,
          minSize: 150,
          maxSize: 400,
          headerHeight: 48,
          title: 'Long List',
          clipContent: true,
          // Icon used for both header and collapsed rail
          icon: const Icon(Icons.chevron_left),
          child: _FakeList(),
        ),

        // CENTER PANEL: Editor
        // Standard widgets automatically fill available space (flex: 1).
        Container(
          color: Colors.white,
          padding: const EdgeInsets.all(16),
          alignment: Alignment.topLeft,
          child: const Text(
            'void main(){\n  print("Hello World");\n}',
            style: TextStyle(fontFamily: 'monospace', fontSize: 14),
          ),
        ),

        // RIGHT PANEL: Properties
        // 2. Panel with Style Overrides
        // This panel overrides the global config to look "Dark".
        InlinePanel(
          id: const PanelId('properties'),
          anchor: PanelAnchor.right,
          width: 280,
          title: 'PROPERTIES',
          clipContent: true,

          // Icon for toggle (collapse/expand)
          // ALWAYS use chevron_left. The system rotates it.
          icon: const Icon(Icons.chevron_left),

          // Overriding visual properties for this specific panel
          headerDecoration: const BoxDecoration(color: Color(0xFF2D2D2D)),
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          iconColor: Colors.white70,
          panelBoxDecoration: const BoxDecoration(color: Color(0xFF1E1E1E)),

          child: const Center(
            child: Text(
              'Dark Theme Panel\n(Overrides Global)',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}

class _FakeList extends StatelessWidget {
  const _FakeList();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 200,
      itemBuilder: (context, index) => ListTile(
        leading: const Icon(Icons.insert_drive_file, size: 16),
        title: Text('file_$index.dart', style: const TextStyle(fontSize: 13)),
        dense: true,
      ),
    );
  }
}
