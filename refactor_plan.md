# Panel Layout Refactor Plan: Declarative "Widget-First" API

**Goal:** Move from an imperative, controller-heavy API to a declarative, widget-centric API where the structure of the UI is defined by the widget tree.

## Current State (Imperative)
Currently, panels are created as `PanelController` objects and manually registered with a `PanelLayoutController`. The `PanelArea` widget then takes a list of IDs to render.

```dart
// 1. Create Controller
final myPanel = PanelController(id: ..., sizing: ...);

// 2. Add to LayoutController
layoutController.registerPanel(myPanel);

// 3. Render
PanelArea(panelIds: [myPanel.id, ...])
```

**Issues:**
- Verbose boilerplate.
- Disconnect between "Definition" and "Usage".
- State synchronization management fell on the user (registering/unregistering).
- Z-ordering was implicit (fixed by recent patch, but still requires manual `zIndex` setting on controllers).

## Proposed State (Declarative)
The `PanelLayout` widget becomes the top-level container. It accepts `Panel` widgets as children.

```dart
PanelLayout(
  children: [
    // Inline Panel
    Panel(
      id: AppMagic.sidebar,
      initialSize: 200,
      minSize: 100,
      resizable: true,
      child: Sidebar(),
    ),
    
    // Flexible Content
    Panel(
      id: AppMagic.content,
      flex: 1, // Implies FlexibleSizing
      child: MainContent(),
    ),
    
    // Overlay Panel (Declarative zIndex!)
    Panel(
      id: AppMagic.settingsOverlay,
      mode: PanelMode.overlay,
      anchor: PanelAnchor.right,
      zIndex: 10, 
      child: Settings(),
    ),
  ],
)
```

## Key Components

### 1. `Panel` Widget
A configuration widget (likely an `InheritedWidget` or just a configuration object used by the parent). It does **not** paint itself directly but holds the metadata:
- `PanelId id`
- `Widget child`
- `PanelMode mode`
- `PanelSizing initialSizing`
- `PanelConstraints constraints`
- `int zIndex`

### 2. `PanelLayout` Widget
The orchestrator.
- **Diffing Engine:** In its `build` or `didUpdateWidget`, it compares the list of `Panel` children with the active `PanelController`s.
- **Auto-Registration:** It automatically registers new panels and unregisters removed ones.
- **Layout Logic:** It internally uses the existing `PanelArea` logic (or a refactored version) to layout the children based on the configuration provided by the `Panel` widgets.

### 3. Context-Aware Access
Users can still access the controller for dynamic actions (open/close) via `PanelScope` or similar.

```dart
Panel.of(context).close();
// or
PanelLayout.of(context).getPanel(id).toggle();
```

## Migration Steps

1.  **Create `Panel` Configuration Widget:** Define the API surface.
2.  **Create `PanelLayout` Wrapper:** Implement the logic to sync `children` list to `PanelLayoutController`.
3.  **Refactor `PanelArea`:** Ideally, `PanelArea` becomes an internal implementation detail of `PanelLayout`.
4.  **Deprecate Imperative API:** Mark manual `registerPanel` as advanced/internal usage.

## Benefits
- **Intuitive:** "What you see is what you get" in the widget tree.
- **Less Code:** No separate controller instantiation lines.
- **Safety:** Harder to have "orphaned" panels or ID mismatches.
- **Hot Reload Friendly:** Changing a `Panel` property in the code immediately updates the layout.
