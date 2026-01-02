import 'package:flutter/material.dart';
import 'package:panel_layout/panel_layout.dart';

class VanillaTab extends StatelessWidget {
  const VanillaTab({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Wrap in PanelLayout to provide the controller
    return PanelLayout(
      builder: (context, controller) {
        // 2. Register panels on initialization
        // Note: In a real app, you might do this in a StatefulWidget's initState
        // or a BLoC, but doing it here is safe because registerPanel is idempotent.
        
        controller.registerPanel(
          const PanelId('left'),
          sizing: const FixedSizing(250),
          mode: PanelMode.inline,
          anchor: PanelAnchor.left,
          constraints: const PanelConstraints(minSize: 100, maxSize: 400),
          visuals: const PanelVisuals(
            showBorders: true,
            useAcrylic: false,
          ),
        );

        controller.registerPanel(
          const PanelId('center'),
          sizing: const FlexibleSizing(1.0),
          mode: PanelMode.inline,
          anchor: PanelAnchor.left, // Anchor doesn't matter much for center/flexible
        );

        controller.registerPanel(
          const PanelId('right'),
          sizing: const FixedSizing(300),
          mode: PanelMode.inline,
          anchor: PanelAnchor.right,
          constraints: const PanelConstraints(minSize: 200, maxSize: 500),
        );

        return Scaffold(
          body: Column(
            children: [
              // Toolbar to control panels
              const VanillaToolbar(),
              
              // The Layout Area
              Expanded(
                child: PanelArea(
                  controller: controller,
                  panelIds: const [
                    PanelId('left'),
                    PanelId('center'),
                    PanelId('right'),
                  ],
                  panelBuilder: (context, id) {
                    if (id.value == 'left') return const Center(child: Text('Left Sidebar'));
                    if (id.value == 'right') return const Center(child: Text('Right Inspector'));
                    return Container(
                      color: Colors.white,
                      child: const Center(child: Text('Main Content')),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class VanillaToolbar extends StatelessWidget {
  const VanillaToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the controller via PanelLayout.of(context)
    // We don't need to listen here, just access methods.
    final controller = PanelLayout.of(context, listen: false);

    return Container(
      height: 50,
      color: Colors.grey[200],
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => controller.getPanel(const PanelId('left'))?.toggle(),
            tooltip: 'Toggle Left Panel',
          ),
          const Spacer(),
          const Text('Vanilla Layout Manager'),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.info),
            onPressed: () => controller.getPanel(const PanelId('right'))?.toggle(),
            tooltip: 'Toggle Right Panel',
          ),
        ],
      ),
    );
  }
}
