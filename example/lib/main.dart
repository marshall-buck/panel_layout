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
      title: 'Panel Layout Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
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
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Panel Layout Desktop Examples'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Classic IDE'),
              Tab(text: 'Vertical Split'),
              Tab(text: 'Anchored Overlays'),
            ],
          ),
        ),
        body: const TabBarView(
          physics: NeverScrollableScrollPhysics(),
          children: [
            ClassicIDELayout(),
            VerticalSplitLayout(),
            AnchoredOverlayLayout(),
          ],
        ),
      ),
    );
  }
}

/// A simple concrete implementation of [BasePanel].
class SimplePanel extends BasePanel {
  const SimplePanel({
    required super.id,
    required super.child,
    super.mode = PanelMode.inline,
    super.anchor = PanelAnchor.left,
    super.anchorTo,
    super.width,
    super.height,
    super.flex,
    super.minSize,
    super.maxSize,
    super.resizable = true,
    super.initialVisible = true,
    super.initialCollapsed = false,
    super.zIndex = 0,
    super.crossAxisAlignment,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: child,
    );
  }
}

class ClassicIDELayout extends StatelessWidget {
  const ClassicIDELayout({super.key});

  @override
  Widget build(BuildContext context) {
    return PanelLayout(
      children: [
        SimplePanel(
          id: const PanelId('explorer'),
          width: 250,
          minSize: 150,
          maxSize: 400,
          child: Column(
            children: [
              _PanelHeader(
                title: 'EXPLORER',
                onClose: () => PanelLayout.of(
                  context,
                ).setVisible(const PanelId('explorer'), false),
              ),
              const Expanded(child: Center(child: Text('File Tree'))),
            ],
          ),
        ),
        SimplePanel(
          id: const PanelId('editor'),
          flex: 1,
          child: Column(
            children: [
              _PanelHeader(
                title: 'main.dart',
                actions: [
                  IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => PanelLayout.of(
                      context,
                    ).toggleVisible(const PanelId('explorer')),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () => PanelLayout.of(
                      context,
                    ).toggleVisible(const PanelId('properties')),
                  ),
                ],
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    'Code Editor Content',
                    style: TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ],
          ),
        ),
        SimplePanel(
          id: const PanelId('properties'),
          anchor: PanelAnchor.right,
          width: 200,
          minSize: 100,
          child: Column(
            children: [
              _PanelHeader(
                title: 'PROPERTIES',
                onClose: () => PanelLayout.of(
                  context,
                ).setVisible(const PanelId('properties'), false),
              ),
              const Expanded(child: Center(child: Text('Settings'))),
            ],
          ),
        ),
      ],
    );
  }
}

class VerticalSplitLayout extends StatelessWidget {
  const VerticalSplitLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return PanelLayout(
      axis: Axis.vertical,
      children: [
        SimplePanel(
          id: const PanelId('top_nav'),
          height: 60,
          resizable: false,
          child: const Center(child: Text('Toolbar / Navigation')),
        ),
        SimplePanel(
          id: const PanelId('main_content'),
          flex: 1,
          child: const Center(child: Text('Main Dashboard')),
        ),
        SimplePanel(
          id: const PanelId('terminal'),
          anchor: PanelAnchor.bottom,
          height: 200,
          minSize: 100,
          child: Column(
            children: [
              _PanelHeader(
                title: 'TERMINAL',
                onClose: () => PanelLayout.of(
                  context,
                ).setVisible(const PanelId('terminal'), false),
              ),
              const Expanded(child: Center(child: Text('Console Output'))),
            ],
          ),
        ),
      ],
    );
  }
}

class AnchoredOverlayLayout extends StatefulWidget {
  const AnchoredOverlayLayout({super.key});

  @override
  State<AnchoredOverlayLayout> createState() => _AnchoredOverlayLayoutState();
}

class _AnchoredOverlayLayoutState extends State<AnchoredOverlayLayout> {
  final _controller = PanelLayoutController();

  @override
  Widget build(BuildContext context) {
    return PanelLayout(
      controller: _controller,
      children: [
        // Main Content
        SimplePanel(
          id: const PanelId('content'),
          flex: 1,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Layout with Anchored Overlay'),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () =>
                      _controller.toggleVisible(const PanelId('side_panel')),
                  child: const Text('Toggle Right Panel'),
                ),
              ],
            ),
          ),
        ),

        // 2. Inline widget anchored to the right of the app, with a fixed width
        SimplePanel(
          id: const PanelId('side_panel'),
          anchor: PanelAnchor.right,
          width: 300,
          child: Column(
            children: [
              _PanelHeader(
                title: 'INLINE RIGHT PANEL',
                actions: [
                  IconButton(
                    icon: const Icon(Icons.auto_awesome_motion),
                    tooltip: 'Open Overlay',
                    onPressed: () => _controller.toggleVisible(
                      const PanelId('overlay_panel'),
                    ),
                  ),
                ],
              ),
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'This panel is inline and fixed width. '
                    'Click the icon above to show an overlay anchored to my left side.',
                  ),
                ),
              ),
            ],
          ),
        ),

        // 3. Overlay panel that animates FROM the left side of the inline panel
        SimplePanel(
          id: const PanelId('overlay_panel'),
          mode: PanelMode.overlay,
          anchor: PanelAnchor.left, // Left of the target
          anchorTo: const PanelId('side_panel'),
          width: 250,
          initialVisible: false,
          zIndex: 10,
          child: Container(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Column(
              children: [
                _PanelHeader(
                  title: 'ANCHORED OVERLAY',
                  onClose: () => _controller.setVisible(
                    const PanelId('overlay_panel'),
                    false,
                  ),
                ),
                const Expanded(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'I am an overlay!\n\nI animate out from the left edge of the side panel.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({required this.title, this.onClose, this.actions});

  final String title;
  final VoidCallback? onClose;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const Spacer(),
          if (actions != null) ...actions!,
          if (onClose != null)
            IconButton(
              icon: const Icon(Icons.close, size: 16),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: onClose,
            ),
        ],
      ),
    );
  }
}
