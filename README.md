# Panel Layout

A modern, declarative, widget-centric panel layout system for Flutter.

`panel_layout` provides a robust engine for building complex user interfaces with resizable panels, flexible content areas, and intelligently anchored overlays.

## Key Features

-   **Declarative API**: Define your layout by simply listing your panels as children of `PanelLayout`.
-   **Type-Safe Panels**: Use `InlinePanel` for docked content and `OverlayPanel` for floating content.
-   **State Persistence**: Panels "remember" their user-dragged sizes and collapse states even if the parent widget tree rebuilds.
-   **Mini Variants (Collapsed Strips)**: Native support for "Mini Drawer" or "Side Rail" patterns. Panels can collapse to a small strip instead of disappearing completely.
-   **Automated Animations**: Smooth, built-in transitions for visibility toggles and collapsing.
-   **Intelligent Anchoring**: Overlay panels can be anchored to the container edges, other panels, or arbitrary `LayerLink` targets.
-   **Styling Agnostic**: The layout engine handles sizing and positioning; you own the visual design of your panels.
-   **High Performance**: Uses `CustomMultiChildLayout` and `InheritedModel` to minimize rebuilds and ensure smooth 60/120fps interactions.

## Getting Started

### 1. Define your Panels

Use `InlinePanel` for panels that participate in the main layout (Row/Column flow).

```dart
InlinePanel(
  id: const PanelId('sidebar'),
  width: 250,
  minSize: 100,
  maxSize: 400,
  anchor: PanelAnchor.left,
  
  // Optional: Define a collapsed "mini" state
  collapsedSize: 48,
  collapsedChild: MySideRail(), 
  
  child: SidebarContent(),
)
```

Use `OverlayPanel` for floating panels (Dialogs, Popovers).

```dart
OverlayPanel(
  id: const PanelId('settings_popup'),
  anchor: PanelAnchor.right,
  anchorTo: const PanelId('sidebar'), // Anchor to another panel!
  width: 300,
  child: SettingsContent(),
)
```

### 2. Assemble the Layout

Place your panels inside a `PanelLayout`.

```dart
PanelLayout(
  children: [
    InlinePanel(...),
    InlinePanel(id: const PanelId('main'), flex: 1, child: MainContent()),
    OverlayPanel(...),
  ],
)
```

## Mini Variants & Collapsing

You can allow panels to collapse into a "Mini Variant" (like a toolbar or icon rail) by providing a `collapsedChild`.

Use the built-in `PanelToggleButton` to easily toggle this state. It automatically detects the panel's anchor and rotates its icon (e.g., a chevron) to point the correct way.

```dart
// Inside your panel content
PanelToggleButton(
  child: Icon(Icons.chevron_left), // Will rotate to point right when collapsed!
)
```

## Programmatic Control

To manipulate the layout from elsewhere in your app (e.g., a button in the AppBar), use the `PanelLayoutController`.

```dart
final controller = PanelLayoutController();

// ... in build ...
PanelLayout(
  controller: controller,
  children: [...],
)

// ... elsewhere ...
IconButton(
  icon: Icon(Icons.menu),
  onPressed: () => controller.toggleVisible(const PanelId('sidebar')),
)
```

## Accessing Panel State

Descendants of a panel can access its real-time runtime state (like whether it is collapsed) using `PanelDataScope`.

```dart
class SidebarContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = PanelDataScope.of(context);
    
    return Column(
      children: [
        if (!state.collapsed) Text("I am expanded!"),
        Text("My current width is ${state.size}"),
      ],
    );
  }
}
```

## Customizing Resize Handles

Use `ResizeHandleTheme` to customize the appearance and behavior of the draggable dividers.

```dart
ResizeHandleTheme(
  data: ResizeHandleThemeData(
    width: 2.0,
    color: Colors.blue,
    hitTestWidth: 12.0,
  ),
  child: PanelLayout(...),
)
```

## Installation

Add `panel_layout` to your `pubspec.yaml`:

```yaml
dependencies:
  panel_layout:
    git:
      url: https://github.com/marshall-buck/panel_layout.git
```