# Panel Layout

A powerful, declarative Flutter package for building complex, resizable, and adaptable panel layouts. `panel_layout` allows you to create IDE-like interfaces, dashboard layouts, and flexible split-views with ease, all without depending on Material or Cupertino libraries.

## Features

* **Declarative Configuration**: Define your layout structure using a simple list of widgets (`InlinePanel`, `OverlayPanel`, or standard widgets).
* **Resizable Panels**: Built-in resize handles that work automatically between inline panels.
* **Ratio & Absolute Sizing**: Mix ratio-based (like standard flex) and absolute-sized (pixel-width) panels seamlessly.
* **Overlay Support**: Easily position independent panels anchored to other panels or the window without affecting the main layout flow.
* **Animations**: Smooth transitions for visibility toggling and collapsing/expanding.
* **Programmatic Control**: Use `PanelLayoutController` to manipulate panel state (visibility, collapse) from anywhere.
* **Framework Agnostic**: Pure Flutter implementation. No dependency on Material or Cupertino, giving you full styling control.

## Getting Started

The core widget is `PanelLayout`. It accepts a list of children, which can be:

1. **`InlinePanel`**: A panel that participates in the linear flow (like a generic Row/Column child).
2. **`OverlayPanel`**: A panel that sits on top of the content, anchored to a specific location or other panels.
3. **Standard `Widget`s**: Any other widget is automatically wrapped in an adapter and treated as a resizable inline panel.

### Basic Usage

Here is a simple example creating a standard "Sidebar - Content - Sidebar" layout.

```dart
import 'package:flutter/widgets.dart';
import 'package:panel_layout/panel_layout.dart';

class MyIdeLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return PanelLayout(
      children: [
        // Left Sidebar (Absolute width)
        InlinePanel(
          id: PanelId('left_sidebar'),
          width: 250, // Starts at 250px, but user can resize
          maxSize: 400,
          minSize: 150,
          child: Container(color: Color(0xFFE0E0E0), child: Text('Explorer')),
        ),

        // Main Content (Ratio-based)
        // Standard widgets fill remaining space automatically (layoutWeight: 1)
        Container(
          color: Color(0xFFFFFFFF),
          child: Center(child: Text('Main Editor')),
        ),

        // Right Sidebar (Ratio-based)
        // Standard widgets fill remaining space automatically.
        // (For custom weight, wrap in InternalLayoutAdapter or similar - future feature)
        Container(color: Color(0xFFEEEEEE), child: Text('Properties')),
      ],
    );
  }
}
```

## Advanced Usage

### Controlling Panels Programmatically

You can control the state of your panels (visibility, collapsed state) using a `PanelLayoutController`. This is optional; the layout manages its own state internally, but a controller allows you to drive changes from buttons or external events.

```dart
class MyControlledLayout extends StatefulWidget {
  @override
  State<MyControlledLayout> createState() => _MyControlledLayoutState();
}

class _MyControlledLayoutState extends State<MyControlledLayout> {
  // Controller is optional, but useful for external triggers
  late final PanelLayoutController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PanelLayoutController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toolbar
        Row(
          children: [
            GestureDetector(
              onTap: () => _controller.toggleVisible(PanelId('sidebar')),
              child: Text('Toggle Sidebar'),
            ),
          ],
        ),
        // Layout
        Expanded(
          child: PanelLayout(
            controller: _controller,
            children: [
              InlinePanel(
                id: PanelId('sidebar'),
                width: 200,
                child: SidebarContent(),
              ),
              MainContent(),
            ],
          ),
        ),
      ],
    );
  }
}
```

### Overlays & Anchoring

`OverlayPanel`s do not affect the layout of other widgets. They render on top and can be anchored anywhere.

```dart
PanelLayout(
  children: [
    InlinePanel(id: PanelId('main'), child: MainContent()),

    // A floating tools palette anchored to the top-right
    OverlayPanel(
      id: PanelId('tools'),
      width: 50,
      height: 200,
      anchor: PanelAnchor.topRight,
      position: Offset(10, 10), // Padding/Offset
      child: ToolsPalette(),
    ),
  ],
)
```

## Under the Hood: Architecture & Mechanics

This section details the internal architecture of the `panel_layout` package. It is intended for those who want to understand how the package manages complex layout requirements, state reconciliation, and performance optimization.

### 1. Declarative Configuration vs. Imperative State

The package bridges the gap between the declarative UI pattern and the imperative nature of resizing state (dragging a handle changes a value).

* **Reconciliation**: On every build, the `PanelLayout` widget processes its `children`. It compares the declarative configuration (e.g., "I want a sidebar of width 200") with its internal `PanelStateManager`.
* **State Persistence**: User interactions (resizing, collapsing) are stored in `PanelStateManager`. When the declarative configuration updates (e.g., parent rebuilds), the manager ensures user-defined state (like a custom width dragged by the user) is preserved unless explicitly overridden.

### 2. The Layout Engine

The core layout logic does not use standard `Row` or `Column` widgets, as they lack the concept of "linked" resizing (where growing one child shrinks another) and stable resize handles.

Instead, it utilizes a `CustomMultiChildLayout` with a specialized `PanelLayoutDelegate` and `PanelLayoutEngine`.

* **`PanelLayoutDelegate`**: This class acts as the bridge between the Flutter render tree and our abstract layout logic. It queries the `PanelStateManager` for the current visual properties (size, visibility) of every ID.
* **`PanelLayoutEngine`**: This is a pure logic class (no Flutter dependencies besides basic geometry). It calculates the specific `Rect` for every panel.
  * It handles the mixing of **Pixel-Sized** (absolute) and **Ratio-Sized** (weighted) panels.
  * It computes the layout in multiple passes: first allocating absolute sizes, then distributing remaining space to remaining panels.

### 3. Resizing Mathematics & Pixel-to-Ratio Calculation

One of the most complex aspects of mixing pixel-defined and ratio-defined panels is resizing.

* **Scenario**: Imagine a 200px absolute panel next to a "ratio: 1" panel.
* **Problem**: If you drag the handle, you are changing the 200px width. But if you have two ratio-based panels, dragging the handle changes their *ratios*, not their pixel widths directly.

To solve this, the engine calculates a **Pixel-to-Weight Ratio** (leveraging Flutter's `flex` concept under the hood) for every frame. This ratio represents how many pixels a single unit of "layoutWeight" value occupies.

* When resizing an **Absolute** panel, we simply adjust its stored pixel size.
* When resizing two **Ratio-based** panels, we convert the drag delta (pixels) into a ratio delta using the current frame's conversion factor: `deltaRatio = deltaPixels / pixelToWeightRatio`.

### 4. Animation & Performance

Animating layout changes (like collapsing a sidebar) is expensive if it triggers a full rebuild of the widget tree every frame. `panel_layout` optimizes this:

* **Isolated Updates**: The `PanelLayoutDelegate` listens to the `PanelStateManager`. When an animation runs, it requests a *layout* update, but does not necessarily trigger a *widget rebuild* of the children.
* **Repaint Boundaries**: Each panel is wrapped in a `RepaintBoundary` (via `AnimatedPanel` structure) so that resizing one panel doesn't force a repaint of its content if the content dimensions haven't changed (though often they do in resizing).
* **Stable Neighbors**: During animation, the engine identifies "stable neighbors" to lock sizing constraints, preventing "wobble" effects where dynamic panels might jitter as available space changes rapidly.

TODO: Make it so it doesn't make a difference the order the panels are included in the panel layout list. The layout should be based on anchoring and not the index order.  maybe??
