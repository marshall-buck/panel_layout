# Panel Layout

A modern, declarative, widget-centric panel layout system for Flutter.

`panel_layout` provides a robust engine for building complex user interfaces with resizable panels, flexible content areas, and intelligently anchored overlays.

## Key Features

- **Declarative API**: Define your layout by simply listing your panels as children of `PanelLayout`.
- **Type-Safe Panels**:
  - **`InlinePanel`**: Participates in the layout flow (pushes other panels aside), affects sibling layout, and supports resizing. Supports "Mini Variants" (collapsing to a strip).
  - **`OverlayPanel`**: Floats on top of the layout, does not affect the position of other widgets, and is ideal for dialogs, popovers, or floating tools. Supports `zIndex`.
- **State Persistence**: Panels "remember" their user-dragged sizes and collapse states even if the parent widget tree rebuilds.
- **Mini Variants (Collapsed Strips)**: Native support for "Mini Drawer" or "Side Rail" patterns (InlinePanel only).
- **Automated Animations**: Smooth, built-in transitions for visibility toggles and collapsing.
- **Intelligent Anchoring**: Overlay panels can be anchored to the container edges, other panels, or arbitrary `LayerLink` targets.
- **Styling Agnostic**: The layout engine handles sizing and positioning; you own the visual design of your panels.
- **High Performance**: Uses `CustomMultiChildLayout` and `InheritedModel` to minimize rebuilds.

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
  // The collapsed size is derived from iconSize + standard padding
  icon: Icon(Icons.chevron_left),
  railDecoration: BoxDecoration(color: Colors.grey),

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

  // Overlay specific properties
  zIndex: 10,
  alignment: Alignment.topRight,

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

## Built-in Headers

Panels often need a title bar with actions. Both `InlinePanel` and `OverlayPanel` include built-in support for a standard header.

```dart
InlinePanel(
  id: const PanelId('inspector'),
  // Header configuration
  title: "Inspector",
  icon: Icon(Icons.close),
  // Tap action defaults to 'collapse' for Inline, 'close' for Overlay

  // Custom styling
  headerDecoration: BoxDecoration(color: Colors.grey[200]),
  titleStyle: TextStyle(fontWeight: FontWeight.bold),

  child: InspectorContent(),
)
```

## Mini Variants & Collapsing (InlinePanel)

You can allow `InlinePanel`s to collapse into an icon rail. The collapsed size is automatically calculated based on the `iconSize`.

The `icon` property allows you to provide an icon (typically a chevron) that will be automatically rotated and displayed in the collapsed strip.

```dart
InlinePanel(
  id: const PanelId('nav'),
  width: 200,

  // Mini Variant Config
  icon: Icon(Icons.chevron_left),
  iconSize: 24.0,

  // Advanced Customization
  railIconAlignment: Alignment.topCenter, // Control where the icon sits
  rotateIcon: true, // Default
  railDecoration: BoxDecoration(color: Colors.blueGrey), // Style the collapsed rail
  railPadding: 16.0, // Optional: Override default padding (18.0)

  child: NavContent(),
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

## Configuration & Styling

You can configure the global styling and behavior of the layout by passing a `PanelLayoutConfig` to the `PanelLayout` constructor. This replaces the need for `PanelTheme` or `ResizeHandleTheme` widgets.

```dart
PanelLayout(
  config: PanelLayoutConfig(
    // Global styling
    headerPadding: 8.0,
    headerDecoration: BoxDecoration(color: Colors.grey[200]),
    panelBoxDecoration: BoxDecoration(color: Colors.white),
    
    // Resize Handle styling
    handleColor: Colors.blue,
    handleWidth: 4.0,
    
    // Animation defaults
    sizeDuration: Duration(milliseconds: 300),
  ),
  children: [...],
)
```

Each panel can override these global defaults by setting its own properties (e.g. `InlinePanel(headerPadding: 12, ...)`).
