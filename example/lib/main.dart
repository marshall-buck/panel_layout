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

/// A wrapper to add consistent styling to panel content.
class PanelContainer extends StatelessWidget {
  const PanelContainer({required this.child, super.key});

  final Widget child;

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

class ClassicIDELayout extends StatefulWidget {
  const ClassicIDELayout({super.key});

  @override
  State<ClassicIDELayout> createState() => _ClassicIDELayoutState();
}

class _ClassicIDELayoutState extends State<ClassicIDELayout> {
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
        InlinePanel(
          id: const PanelId('explorer'),
          width: 250,
          minSize: 150,
          maxSize: 400,
          collapsedSize: 48,
          toggleIcon: const Icon(Icons.chevron_left),
          collapsedDecoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: PanelContainer(
            child: Column(
              children: [
                _PanelHeader(
                  title: 'EXPLORER',
                  actions: [
                    Builder(
                      builder: (context) {
                        return IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () {
                            final panelId =
                                PanelDataScope.maybeOf(context)!.config.id;
                            PanelScope.of(context).toggleCollapsed(panelId);
                          },
                        );
                      },
                    ),
                  ],
                ),
                const Expanded(child: Center(child: Text('File Tree'))),
              ],
            ),
          ),
        ),
        InlinePanel(
          id: const PanelId('editor'),
          flex: 1,
          child: PanelContainer(
            child: Column(
              children: [
                _PanelHeader(
                  title: 'main.dart',
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () =>
                          _controller.toggleVisible(const PanelId('explorer')),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings),
                      onPressed: () =>
                          _controller.toggleVisible(const PanelId('properties')),
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
        ),
        InlinePanel(
          id: const PanelId('properties'),
          anchor: PanelAnchor.right,
          width: 200,
          minSize: 100,
          child: PanelContainer(
            child: Column(
              children: [
                _PanelHeader(
                  title: 'PROPERTIES',
                  onClose: () =>
                      _controller.setVisible(const PanelId('properties'), false),
                ),
                const Expanded(child: Center(child: Text('Settings'))),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class VerticalSplitLayout extends StatefulWidget {
  const VerticalSplitLayout({super.key});

  @override
  State<VerticalSplitLayout> createState() => _VerticalSplitLayoutState();
}

class _VerticalSplitLayoutState extends State<VerticalSplitLayout> {
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
      axis: Axis.vertical,
      children: [
        InlinePanel(
          id: const PanelId('top_nav'),
          height: 60,
          resizable: false,
          child: const PanelContainer(
            child: Center(child: Text('Toolbar / Navigation')),
          ),
        ),
        InlinePanel(
          id: const PanelId('main_content'),
          flex: 1,
          child: const PanelContainer(
            child: Center(child: Text('Main Dashboard')),
          ),
        ),
        InlinePanel(
          id: const PanelId('terminal'),
          anchor: PanelAnchor.bottom,
          height: 200,
          minSize: 100,
          collapsedSize: 32,
          toggleIcon: const Icon(Icons.chevron_left, size: 16),
          collapsedDecoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          child: PanelContainer(
            child: Column(
              children: [
                _PanelHeader(
                  title: 'TERMINAL',
                  actions: [
                    Builder(
                      builder: (context) {
                        return IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: () {
                            final panelId =
                                PanelDataScope.maybeOf(context)!.config.id;
                            PanelScope.of(context).toggleCollapsed(panelId);
                          },
                        );
                      },
                    ),
                  ],
                ),
                const Expanded(child: Center(child: Text('Console Output'))),
              ],
            ),
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PanelLayout(
      controller: _controller,
      children: [
        // Main Content
        InlinePanel(
          id: const PanelId('content'),
          flex: 1,
          child: PanelContainer(
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
        ),

        // 2. Inline widget anchored to the right of the app, with a fixed width
        InlinePanel(
          id: const PanelId('side_panel'),
          anchor: PanelAnchor.right,
          width: 300,
          child: PanelContainer(
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
        ),

        // 3. Overlay panel that animates FROM the left side of the inline panel
        OverlayPanel(
          id: const PanelId('overlay_panel'),
          anchor: PanelAnchor.left, // Left of the target
          anchorTo: const PanelId('side_panel'),
          width: 250,
          initialVisible: false,
          initialCollapsed: false,
          zIndex: 10,
          child: PanelContainer(
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
