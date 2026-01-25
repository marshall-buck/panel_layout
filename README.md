# Panel Layout

A modern, declarative, widget-centric panel layout system for Flutter.

`panel_layout` provides a robust engine for building complex user interfaces with resizable panels, flexible content areas, and intelligently anchored overlays.

## Key Features

- **Declarative API**: Define your layout by simply listing your panels as children of `PanelLayout`.
- **Centralized Configuration**: Type-safe `PanelStyle` for global styling and behavior (animations, resize handles).
- **Type-Safe Panels**:
  - **`InlinePanel`**: Tiled panels that participate in the flow (Row/Column). Supports resizing and "Mini Variants" (collapsing to a rail).
  - **`OverlayPanel`**: Floating panels anchored to edges or specific widget IDs. Ideal for dialogs and popovers.
- **State Persistence**: Panels automatically persist their user-dragged sizes and collapse states during rebuilds.
- **Automated Animations**: Smooth, built-in transitions for visibility toggles and collapsing.
- **Intelligent Anchoring**: Overlay panels can be anchored to any other panel or `LayerLink`.
- **High Performance**: Optimized layout engine minimizes rebuilds using `CustomMultiChildLayout`.

## Installation

```yaml
dependencies:
  panel_layout: latest
```

## Usage Guide

### 1. The Root: PanelLayout & Configuration

The `PanelLayout` widget is the entry point. It infers the layout direction from its children and holds the global style configuration.

```dart
PanelLayout(
  // 1. Global Configuration (Optional)
  style: PanelStyle(
    // Styling
    headerPadding: 8.0,
    headerDecoration: BoxDecoration(color: Colors.grey[200]),
    panelBoxDecoration: BoxDecoration(color: Colors.white),

    // Resize Handles
    handleColor: Colors.blueAccent,
    handleWidth: 4.0,

    // Animation Speeds
    sizeDuration: Duration(milliseconds: 300),
  ),

  // 3. Controller (Optional, for programmatic access)
  controller: myPanelController,

  // 4. Children (The Panels)
  children: [
    // ... panels go here
  ],
)
```

### 2. The Building Blocks: InlinePanel

`InlinePanel`s are tiles that change the layout. They can be fixed-size, flexible, or content-sized.

```dart
InlinePanel(
  id: const PanelId('sidebar'),

  // Sizing
  width: 250,        // Fixed width
  minSize: 100,      // Constraint
  maxSize: 400,

  // Header Config
  title: "Explorer",
  icon: Icon(Icons.chevron_left), // Use chevron_left for auto-rotation!

  // Content
  child: ListView(...),
)
```

**Fluid Panels:** Use `flex` to make a panel fill remaining space.

```dart
InlinePanel(
  id: const PanelId('editor'),
  flex: 1, // Takes all remaining space
  child: EditorWidget(),
)
```

### 3. Specialized Panels: UserContent

For content regions that should fill the remaining space (`flex: 1`) without headers, decorations, or resize handles between them, extend the `UserContent` class.

```dart
class MyEditorPanel extends UserContent {
  const MyEditorPanel({super.key, required super.id});

  @override
  Widget buildContent(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(child: Text("Editor")),
    );
  }
}

// Usage in PanelLayout
PanelLayout(
  children: [
    InlinePanel(...), // Sidebar
    MyEditorPanel(id: PanelId('editor')), // Fills space
    MyPreviewPanel(id: PanelId('preview')), // Fills space, no resize handle between editors
  ],
)
```

### 4. Floating Content: OverlayPanel

`OverlayPanel`s float on top of the layout. They are removed from the flow but can be anchored to specific points.

```dart
OverlayPanel(
  id: const PanelId('settings_dialog'),

  // Anchor to the Right edge of the whole layout
  anchor: PanelAnchor.right,

  // OR Anchor to a specific panel
  anchorTo: const PanelId('sidebar'),

  width: 300,
  initialVisible: false,

  child: SettingsWidget(),
)
```

### 4. Controlling State

Use `PanelLayoutController` to toggle panels from anywhere.

```dart
final controller = PanelLayoutController();

// ... pass to PanelLayout ...

// ... later ...
controller.toggleVisible(const PanelId('sidebar'));
controller.toggleCollapsed(const PanelId('sidebar'));
```

## Advanced Features

### Mini Variants (Collapsible Rails)

`InlinePanel`s natively support collapsing into a "Rail" or "Mini Drawer".
When `collapsed` is true, the panel shrinks to fit its icon (plus padding).

```dart
InlinePanel(
  id: const PanelId('nav'),
  width: 200,

  // The icon displayed in the header AND the rail
  icon: Icon(Icons.chevron_left),

  // Rail Styling
  railDecoration: BoxDecoration(color: Colors.blueGrey),
  railIconAlignment: Alignment.topCenter,

  child: NavMenu(),
)
```

### Styling Hierarchy

`panel_layout` uses a strict hierarchy for resolving styles. You can override styles at any level:

1. **Panel Instance**: `InlinePanel(headerPadding: 20)` (Highest Priority)
2. **Global Config**: `PanelLayout(style: PanelStyle(headerPadding: 10))`
3. **Library Defaults**: `8.0`

### Accessing State in Children

Descendants of a panel can read their own state (e.g., to hide text when collapsed) using `PanelDataScope`.

```dart
Widget build(BuildContext context) {
  final state = PanelDataScope.of(context);

  if (state.collapsed) {
    return Icon(Icons.home);
  } else {
    return Text("Home");
  }
}
```

### Scoped Configuration

Since `PanelStyle` is an `InheritedWidget`, you can nest layouts to create scoped themes.

```dart
PanelLayout(
  style: DarkThemeConfig, // Outer layout is Dark
  children: [
    InlinePanel(
      id: PanelId('sidebar'), // Uses Dark Theme
      // ...
    ),
    InlinePanel(
      flex: 1,
      child: PanelLayout(
        style: LightThemeConfig, // Inner layout is Light
        children: [
          // These panels use Light Theme
        ],
      ),
    ),
  ],
)
```
