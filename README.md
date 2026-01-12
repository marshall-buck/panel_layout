# Panel Layout

A modern, declarative, widget-centric panel layout system for Flutter.

`panel_layout` provides a robust engine for building complex user interfaces with resizable panels, flexible content areas, and intelligently anchored overlays.

## The Declarative Shift (v0.4.0+)

Starting with version 0.4.0, the package has moved to a **"Widget-First"** declarative API. Instead of manually registering controllers, you define your layout structure directly in the widget tree. The engine automatically handles state preservation, resizing interactions, and frame-perfect animations.

## Key Features

-   **Declarative API**: Define your layout by simply listing your panels as children of `PanelLayout`.
-   **State Persistence**: Panels "remember" their user-dragged sizes and collapse states even if the parent widget tree rebuilds.
-   **Automated Animations**: Smooth, built-in transitions for visibility toggles and collapsing.
-   **Intelligent Anchoring**: Overlay panels can be anchored to the container edges, other panels, or arbitrary `LayerLink` targets.
-   **Styling Agnostic**: The layout engine handles sizing and positioning; you own the visual design of your panels by extending `BasePanel`.
-   **High Performance**: Uses `CustomMultiChildLayout` and `InheritedModel` to minimize rebuilds and ensure smooth 60/120fps interactions.

## Getting Started

### 1. Define your Panels

Create your panels by extending the `BasePanel` class. This encapsulates your panel's configuration and its content.

```dart
class MySidebar extends BasePanel {
  MySidebar() : super(
    id: const PanelId('sidebar'),
    width: 250,
    minSize: 100,
    maxSize: 400,
    anchor: PanelAnchor.left,
    child: SidebarContent(),
  );
}
```

### 2. Assemble the Layout

Place your panels inside a `PanelLayout`.

```dart
PanelLayout(
  children: [
    MySidebar(),
    MyMainContent(), // Another class extending BasePanel with flex: 1
  ],
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

## Running the Example

The `example/` directory contains a minimal setup to demonstrate the package. To run it:

1.  Navigate to the `example` directory:
    ```bash
    cd example
    ```
2.  Initialize the Flutter project structure (this creates the `ios`, `android`, `web`, `macos`, etc., directories):
    ```bash
    flutter create .
    ```
3.  Run the app:
    ```bash
    flutter run -d macos  # or windows, linux, etc.
    ```
