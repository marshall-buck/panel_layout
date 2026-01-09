import 'package:flutter/widgets.dart';
import 'package:panel_layout/panel_layout.dart';

/// A pure widgets example without Material dependency.
class VanillaTab extends StatelessWidget {
  const VanillaTab({super.key});

  @override
  Widget build(BuildContext context) {
    return PanelLayout(
      builder: (context, controller) {
        controller.registerPanel(
          const PanelId('left'),
          sizing: const FixedSizing(250),
          mode: PanelMode.inline,
          anchor: PanelAnchor.left,
          constraints: const PanelConstraints(minSize: 100, maxSize: 400),
          builder: (context, _) => Container(
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: Color(0xFFCCCCCC))),
            ),
            child: const Center(
              child: Text(
                'Left Sidebar',
                style: TextStyle(
                  color: Color(0xFF000000),
                  fontSize: 14,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        );

        controller.registerPanel(
          const PanelId('center'),
          sizing: const FlexibleSizing(1.0),
          mode: PanelMode.inline,
          anchor: PanelAnchor.left,
          builder: (context, _) => Container(
            color: const Color(0xFFF0F0F0),
            child: const Center(
              child: Text(
                'Main Content',
                style: TextStyle(
                  color: Color(0xFF000000),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        );

        controller.registerPanel(
          const PanelId('right'),
          sizing: const FixedSizing(300),
          mode: PanelMode.inline,
          anchor: PanelAnchor.right,
          constraints: const PanelConstraints(minSize: 200, maxSize: 500),
          builder: (context, _) => Container(
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: Color(0xFFCCCCCC))),
            ),
            child: const Center(
              child: Text(
                'Right Inspector',
                style: TextStyle(
                  color: Color(0xFF000000),
                  fontSize: 14,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        );

        return Container(
          color: const Color(0xFFFFFFFF),
          child: Column(
            children: [
              const VanillaToolbar(),
              Expanded(
                child: PanelArea(
                  panelLayoutController: controller,
                  panelIds: const [
                    PanelId('left'),
                    PanelId('center'),
                    PanelId('right'),
                  ],
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
    final controller = PanelLayout.of(context, listen: false);

    return Container(
      height: 50,
      color: const Color(0xFFE0E0E0),
      child: Row(
        children: [
          _SimpleButton(
            text: 'Toggle Left',
            onTap: () => controller.getPanel(const PanelId('left'))?.toggle(),
          ),
          const Spacer(),
          const Text(
            'Vanilla Layout (Pure Widgets)',
            style: TextStyle(
              color: Color(0xFF000000),
              fontSize: 14,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.none,
            ),
          ),
          const Spacer(),
          _SimpleButton(
            text: 'Toggle Right',
            onTap: () => controller.getPanel(const PanelId('right'))?.toggle(),
          ),
        ],
      ),
    );
  }
}

class _SimpleButton extends StatefulWidget {
  const _SimpleButton({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  State<_SimpleButton> createState() => _SimpleButtonState();
}

class _SimpleButtonState extends State<_SimpleButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _hover ? const Color(0xFFCCCCCC) : const Color(0xFFDDDDDD),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            widget.text,
            style: const TextStyle(
              color: Color(0xFF000000),
              fontSize: 12,
              decoration: TextDecoration.none,
            ),
          ),
        ),
      ),
    );
  }
}
