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
        headerHeight: 36.0,
        headerIconSize: 18.0,
        headerIconColor: Colors.black87,
        headerTextStyle: const TextStyle(
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
        panelDecoration: BoxDecoration(
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
          // Icon in header to collapse
          headerIcon: const Icon(Icons.chevron_left),
          // Icon in collapsed strip to expand
          toggleIcon: const Icon(Icons.chevron_left),
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
          headerIcon: const Icon(Icons.close),
          toggleIcon: const Icon(Icons.menu),

          // Explicitly set action to CLOSE (hide) instead of the default COLLAPSE
          headerAction: PanelAction.close,

          // Overriding visual properties for this specific panel
          headerDecoration: const BoxDecoration(color: Color(0xFF2D2D2D)),
          headerTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          headerIconColor: Colors.white70,
          decoration: const BoxDecoration(color: Color(0xFF1E1E1E)),

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
          headerIcon: const Icon(Icons.chevron_left),
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
// Demonstrates: Overlay panels, Anchor positioning
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
        // Background Content
        InlinePanel(
          id: const PanelId('bg'),
          flex: 1,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Press the button to show overlay'),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    _controller.setVisible(const PanelId('overlay'), true);
                  },
                  child: const Text('Open Settings Overlay'),
                ),
              ],
            ),
          ),
        ),

        // 3. Overlay Panel
        // 4. Correct icon usage (Close icon for overlay)
        OverlayPanel(
          id: const PanelId('overlay'),
          width: 300,
          // Anchored to the right side of the screen
          anchor: PanelAnchor.right,
          // Start hidden
          initialVisible: false,
          initialCollapsed: false,

          title: 'SETTINGS OVERLAY',
          // Use a close icon for overlays as they usually "dismiss" rather than "collapse" to a strip
          headerIcon: const Icon(Icons.close),

          // Distinct decoration to make it pop over the content
          decoration: BoxDecoration(
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
