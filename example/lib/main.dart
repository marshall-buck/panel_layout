import 'package:flutter/material.dart';
import 'package:panel_layout/panel_layout.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Panel Layout Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      home: const ExampleHome(),
    );
  }
}

class ExampleHome extends StatelessWidget {
  const ExampleHome({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Base Theme Setup
    // We wrap the entire example area in a PanelTheme to establish default styling.
    return PanelTheme(
      data: PanelThemeData(
        headerPadding: 8.0,

        titleStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
          letterSpacing: 0.5,
        ),
        headerDecoration: BoxDecoration(
          color: Colors.grey[200],
          border: Border(
            bottom: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
        ),
        panelBoxDecoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Panel Layout Gallery'),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Classic IDE', icon: Icon(Icons.grid_view)),
                Tab(text: 'Vertical Split', icon: Icon(Icons.splitscreen)),
                Tab(text: 'Overlays', icon: Icon(Icons.layers)),
              ],
            ),
          ),
          body: const TabBarView(
            physics: NeverScrollableScrollPhysics(),
            children: [ClassicIdeTab(), VerticalSplitTab(), OverlaysTab()],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Tab 1: Classic IDE
// Demonstrates: Inline panels, Resizable panels, Theme Overrides
// -----------------------------------------------------------------------------
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
      children: [
        // LEFT PANEL: Explorer
        // Standard usage. Inline, resizable.
        InlinePanel(
          id: const PanelId('explorer'),
          width: 250,
          minSize: 150,
          maxSize: 400,
          title: 'EXPLORER',
          // Icon used for both header and collapsed rail
          icon: const Icon(Icons.chevron_left),
          child: ListView.builder(
            itemCount: 20,
            itemBuilder: (context, index) => ListTile(
              leading: const Icon(Icons.insert_drive_file, size: 16),
              title: Text(
                'file_$index.dart',
                style: const TextStyle(fontSize: 13),
              ),
              dense: true,
            ),
          ),
        ),

        // CENTER PANEL: Editor
        // Flex 1 to fill space.
        InlinePanel(
          id: const PanelId('editor'),
          flex: 1,
          title: 'main.dart',
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            alignment: Alignment.topLeft,
            child: const Text(
              'void main(){\n  print("Hello World");\n}',
              style: TextStyle(fontFamily: 'monospace', fontSize: 14),
            ),
          ),
        ),

        // RIGHT PANEL: Properties
        // 2. Panel with Theme Changes
        // This panel overrides the global theme to look "Dark".
        InlinePanel(
          id: const PanelId('properties'),
          anchor: PanelAnchor.right,
          width: 280,
          title: 'PROPERTIES',

          // Icon for toggle (collapse/expand)
          icon: const Icon(Icons.chevron_right),

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

// -----------------------------------------------------------------------------
// Tab 2: Vertical Split
// Demonstrates: Vertical axis, Non-resizable panels
// -----------------------------------------------------------------------------
class VerticalSplitTab extends StatelessWidget {
  const VerticalSplitTab({super.key});

  @override
  Widget build(BuildContext context) {
    return PanelLayout(
      axis: Axis.vertical,
      children: [
        // TOP PANEL: Header / Toolbar
        // 6. Non-resizable panel
        InlinePanel(
          id: const PanelId('header'),
          height: 60,
          resizable: false, // User cannot resize this
          title: 'TOOLBAR (FIXED)',
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
        InlinePanel(
          id: const PanelId('content'),
          flex: 1,
          child: const Center(child: Text('Main Content Area')),
        ),

        // BOTTOM PANEL: Terminal
        // Resizable
        InlinePanel(
          id: const PanelId('terminal'),
          anchor: PanelAnchor.bottom,
          height: 150,
          title: 'TERMINAL',
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

// -----------------------------------------------------------------------------
// Tab 3: Overlays
// Demonstrates: Overlay panels, Anchor positioning, Z-Order
// -----------------------------------------------------------------------------
class OverlaysTab extends StatefulWidget {
  const OverlaysTab({super.key});

  @override
  State<OverlaysTab> createState() => _OverlaysTabState();
}

class _OverlaysTabState extends State<OverlaysTab> {
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
      children: [
        // 1. Z-Order Demo: Popover Overlay
        // Placed FIRST in the list so it paints BEHIND the Right Sidebar.
        // Anchored to the LEFT of 'right_sidebar'.
        OverlayPanel(
          id: const PanelId('popover_behind'),
          anchorTo: const PanelId('right_sidebar'),
          anchor: PanelAnchor.left,
          width: 200,
          initialVisible: false,
          title: 'POPOVER',
          icon: const Icon(Icons.close),
          panelBoxDecoration: BoxDecoration(
            color: Colors.amber[50],
            border: Border.all(color: Colors.amber[300]!),
            // Shadow ensures it looks like a distinct layer, but z-order puts it "under" the sidebar
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(-5, 0),
              ),
            ],
          ),
          child: const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'I animated out from BEHIND the sidebar!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.brown),
              ),
            ),
          ),
        ),

        // 2. Main Content
        InlinePanel(
          id: const PanelId('bg'),
          flex: 1,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Main Content Area'),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    _controller.setVisible(const PanelId('overlay'), true);
                  },
                  child: const Text('Open Global Overlay'),
                ),
              ],
            ),
          ),
        ),

        // 3. Right Sidebar
        // Anchored Right. The 'popover_behind' attaches to this panel's left edge.
        InlinePanel(
          id: const PanelId('right_sidebar'),
          anchor: PanelAnchor.right,
          width: 250,
          title: 'SIDEBAR',
          icon: const Icon(Icons.chevron_right),
          child: Column(
            children: [
              const ListTile(
                title: Text('Sidebar Content'),
                subtitle: Text('Click below to test Z-Order'),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () {
                    _controller.toggleVisible(const PanelId('popover_behind'));
                  },
                  child: const Text('Toggle Popover (Behind)'),
                ),
              ),
            ],
          ),
        ),

        // 4. Global Overlay (Existing)
        OverlayPanel(
          id: const PanelId('overlay'),
          width: 300,
          // Anchored to the right side of the screen
          anchor: PanelAnchor.right,
          // Start hidden
          initialVisible: false,

          title: 'SETTINGS OVERLAY',
          // Use a close icon for overlays as they usually "dismiss" rather than "collapse" to a strip
          icon: const Icon(Icons.close),

          // Distinct decoration to make it pop over the content
          panelBoxDecoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.2),
                blurRadius: 15,
                offset: const Offset(-5, 5),
              ),
            ],
            border: Border.all(color: Colors.grey[300]!),
          ),

          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(16),
            children: const [
              Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
              Divider(),
              SwitchListTile(
                value: true,
                onChanged: null,
                title: Text('Notifications'),
              ),
              SwitchListTile(
                value: false,
                onChanged: null,
                title: Text('Dark Mode'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
