import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_panels/flutter_panels.dart';

class OverlaysTab extends StatefulWidget {
  const OverlaysTab({super.key});

  @override
  State<OverlaysTab> createState() => _OverlaysTabState();
}

class _OverlaysTabState extends State<OverlaysTab>
    with AutomaticKeepAliveClientMixin {
  final _rootController = PanelAreaController();
  final _innerController = PanelAreaController();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _rootController.dispose();
    _innerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // ROOT LAYOUT: Vertical
    // Manages the Top Bar, the Content Area, and Global Overlays.
    return PanelArea(
      controller: _rootController,
      style: kAppPanelStyle,
      children: [
        // 1. Top Panel (Inline, Fixed Height)
        InlinePanel(
          id: const PanelId('top_bar'),
          anchor: PanelAnchor.top,
          height: 60,
          title: 'TOP BAR (Nested Layout)',
          icon: const Icon(Icons.chevron_left),
          child: Container(
            color: Colors.blue[50],
            alignment: Alignment.center,
            child: const Text(
              'I am an InlinePanel in the Root Vertical Layout',
            ),
          ),
        ),

        // 2. Content Area (Inline, Flex)
        // Contains the nested Horizontal Layout.
        PanelArea(
          controller: _innerController,
          style: kAppPanelStyle,
          children: [
            // 2a. Z-Order Demo: Popover Overlay (Inner Scope)
            // Anchored to 'right_sidebar' within this inner layout.
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

            // 2b. Main Content (Inner Scope)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Main Content Area (Nested Horizontal)'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      // Opens 'overlay' which is in the Root Layout
                      _rootController.setVisible(
                        const PanelId('overlay'),
                        true,
                      );
                    },
                    child: const Text('Open Global Overlay'),
                  ),
                ],
              ),
            ),

            // 2c. Right Sidebar (Inner Scope)
            InlinePanel(
              id: const PanelId('right_sidebar'),
              anchor: PanelAnchor.right,
              width: 250,
              title: 'SIDEBAR',
              clipContent: true,
              icon: const Icon(Icons.chevron_left),
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
                        _innerController.toggleVisible(
                          const PanelId('popover_behind'),
                        );
                      },
                      child: const Text('Toggle Popover (Behind)'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // 3. Global Overlay (Root Scope)
        // Covers the entire screen including the Top Bar.
        OverlayPanel(
          id: const PanelId('overlay'),
          width: 300,
          anchor: PanelAnchor.right,
          initialVisible: false,
          title: 'SETTINGS OVERLAY',
          icon: const Icon(Icons.close),
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
