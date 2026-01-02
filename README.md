# Panel Layout

A pure Flutter, dependency-free, state-management-agnostic panel system.

`panel_layout` provides a robust "VS Code-like" layout engine for Flutter applications. It handles resizable sidebars, flexible content areas, and overlay panels (drawers) without imposing any specific state management solution (like BLoC or Provider) on your application.

## Features

-   **State Agnostic**: Works with `setState`, `Bloc`, `Riverpod`, `Provider`, or raw `ValueNotifier`.
-   **Resizable Panels**: Built-in drag handles for resizing fixed and flexible panels.
-   **Flexible Layouts**: Supports `Fixed` (pixels), `Flexible` (weight), and `Content` (intrinsic) sizing.
-   **Modes**:
    -   `Inline`: Panels flow in a Row/Column (pushing content).
    -   `Overlay`: Panels float on top (like drawers/modals).
-   **Theming**: customizable borders, resize handles, and "Acrylic" blur effects via `PanelTheme`.
-   **Granular Rebuilds**: Layout structure rebuilds only when necessary, keeping performance high.

## Getting Started

Add the dependency to your `pubspec.yaml`:

```yaml
dependencies:
  panel_layout: ^0.0.1
```

## Usage

### 1. Wrap your app in `PanelLayout`

This widget initializes the `LayoutController` and exposes it to the tree.

```dart
PanelLayout(
  builder: (context, controller) {
    // Register your panels here (safe to call multiple times)
    controller.registerPanel(
      const PanelId('left_sidebar'),
      sizing: const FixedSizing(250),
      mode: PanelMode.inline,
      anchor: PanelAnchor.left,
    );
    
    return MaterialApp(home: HomeScreen());
  },
)
```

### 2. Define the Layout Area

Use `PanelArea` to arrange your panels.

```dart
PanelArea(
  controller: PanelLayout.of(context),
  axis: Axis.horizontal,
  panelIds: const [
    PanelId('left_sidebar'),
    PanelId('main_content'),
  ],
  panelBuilder: (context, id) {
    if (id.value == 'main_content') {
      return Center(child: Text('Main Content'));
    }
    return SidebarWidget();
  },
)
```

### 3. Control Panels

Access the controller from anywhere in the tree to toggle visibility or resize panels.

```dart
final controller = PanelLayout.of(context);
controller.getPanel(const PanelId('left_sidebar'))?.toggle();
```

## State Management Integration

### Vanilla (Pure Flutter)

The package uses `ChangeNotifier` internally. `PanelLayout.of(context)` gives you the controller. To react to changes, you can use `ListenableBuilder` on a specific panel, or rely on `PanelArea` (which handles layout rebuilds automatically).

### Using with BLoC / Cubit

If you manage your app state (like "isSidebarVisible") in a Cubit, you can sync it with the layout system.

**Pattern: The Sync Listener**

Wrap your UI in a `BlocListener` that updates the controller when state changes.

```dart
BlocListener<LayoutCubit, LayoutState>(
  listener: (context, state) {
    final controller = PanelLayout.of(context, listen: false);
    
    // Sync BLoC state -> Layout System
    controller.getPanel(const PanelId('left'))
        ?.setVisible(visible: state.isLeftVisible);
  },
  child: PanelArea(...),
)
```

## Styling

Wrap your tree in `PanelTheme` to customize colors and dimensions.

```dart
PanelTheme(
  data: PanelThemeData(
    backgroundColor: Colors.white,
    borderColor: Colors.grey[300]!,
    resizeHandleWidth: 4.0,
    resizeHandleHoverColor: Colors.blue,
  ),
  child: ...
)
```

## Concepts

-   **`PanelId`**: A strongly-typed identifier for your panels.
-   **`PanelSizing`**:
    -   `FixedSizing(pixels)`: Maintains a specific width/height.
    -   `FlexibleSizing(weight)`: Shares available space (like `Expanded`).
    -   `ContentSizing()`: Sizes to fit its child (intrinsic).
-   **`PanelMode`**:
    -   `inline`: Affects layout flow.
    -   `overlay`: Floats on top.