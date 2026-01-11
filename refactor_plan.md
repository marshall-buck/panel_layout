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
The `PanelLayout` widget becomes the top-level container. It accepts `BasePanel` widgets as children. The `BasePanel` widget holds all the configuration properties.

```dart
PanelLayout(
  children: [
    // Inline Panel (Minimal boilerplate)
    BasePanel(
      id: AppMagic.sidebar,
      width: 200,          // Implies FixedSizing(200)
      child: Sidebar(),
    ),

    // Flexible Content
    BasePanel(
      id: AppMagic.content,
      flex: 1,             // Implies FlexibleSizing(1.0)
      child: MainContent(),
    ),

    // Overlay Panel
    BasePanel(
      id: AppMagic.settingsOverlay,
      mode: PanelMode.overlay,
      anchor: PanelAnchor.right,
      anchorTo: AppMagic.sidebar,
      child: SettingsPanel(),
    ),
  ],
)
```

## Key Components

### 1. `BasePanel` Widget (The Configuration)
A configuration widget that wraps the user's content.

**Required Properties:**
*   `id`: Unique `PanelId` for state tracking and anchoring.
*   `child`: The content `Widget`.
*   `mode`: `PanelMode` (Inline, Overlay, etc.)
*   **`anchor`**: `PanelAnchor` (Left, Right, Top, Bottom)

**Ease of Implementation (Smart Defaults):**
*   **Sizing**: `width`/`height` (Fixed), `flex` (Flexible), or neither (Content).
*   **Constraints**: Simple `minSize`, `maxSize`, `collapsedSize` parameters.
*   **Animation**: Direct `animationDuration` and `animationCurve` parameters.

| Property             | Type                  | Description                              |
| :------------------- | :-------------------- | :--------------------------------------- |
| **Identity**         |                       |                                          |
| `id`                 | `PanelId`             | **Required.** Unique identifier.         |
| **Content**          |                       |                                          |
| `child`              | `Widget`              | **Required.** The content to display.    |
| **Layout & Sizing**  |                       |                                          |
| `width` / `height`   | `double?`             | Set for **FixedSizing**.                 |
| `flex`               | `double?`             | Set for **FlexibleSizing**.              |
| `minSize`            | `double?`             | Minimum size constraint.                 |
| `maxSize`            | `double?`             | Maximum size constraint.                 |
| `collapsedSize`      | `double?`             | Size when collapsed (default 0).         |
| **Positioning**      |                       |                                          |
| `mode`               | `PanelMode`           | **Required.** (Inline, Overlay, etc.)    |
| `anchor`             | `PanelAnchor`         | **Required.** (Left, Right, Top, Bottom) |
| `anchorTo`           | `PanelId?`            | Anchors to another panel.                |
| `anchorLink`         | `LayerLink?`          | Anchors to external widget.              |
| `alignment`          | `Alignment?`          | Alignment override.                      |
| `crossAxisAlignment` | `CrossAxisAlignment?` | Cross-axis behavior.                     |
| **Behavior & State** |                       |                                          |
| `resizable`          | `bool`                | Defaults to `true`.                      |
| `visible`            | `bool`                | Defaults to `true`.                      |
| `collapsed`          | `bool`                | Defaults to `false`.                     |
| **Animation**        |                       |                                          |
| `zIndex`             | `int`                 | Paint order (Higher is on top).          |
| `animationDuration`  | `Duration?`           | Optional. Size/slide duration.           |
| `animationCurve`     | `Curve?`              | Optional. Animation curve.               |

**Simplification Note:** The `sizing`, `constraints`, and `visuals` objects are removed from the public API. `BasePanel` will internally construct them based on the simple scalar values provided.


**Simplification Note:** The `sizing` and `constraints` objects are removed from the public API. `BasePanel` will internally construct them based on the simple `width`, `flex`, and `minSize` values provided.

### 2. `PanelLayout` Widget (The Orchestrator)
The orchestrator that manages the lifecycle of panels.
- **Diffing Engine:** In its `build` or `didUpdateWidget`, it compares the list of `Panel` children with the active `PanelController`s.
- **Auto-Registration:** It automatically registers new panels and unregisters removed ones.
- **Property Sync:** It updates the properties of existing controllers (e.g., if you change `zIndex` or `sizing` in the widget tree, the controller updates).
- **Layout Logic:** It internally uses the existing `PanelArea` logic to layout the children.

### 3. Context-Aware Access
Users can still access the controller for dynamic actions (open/close) via `PanelScope` or similar.

```dart
Panel.of(context).close();
// or
PanelLayout.of(context).panel(id).toggle();
```

## Migration Plan

### Phase 0: Constants & Theme Expansion
Before refactoring the widgets, we will solidify the styling infrastructure.
1.  **Create `lib/src/constants.dart`:**
    *   Define primitive constants for all defaults (e.g., `kDefaultHandleWidth`, `kDefaultHandleColor`, `kDefaultAnimationDuration`).
    *   Ensure no "magic numbers" remain in the code.
2.  **Update `PanelThemeData`:**
    *   Add support for Handle Icons (Grips):
        *   `resizeHandleIcon` (`IconData?`)
        *   `resizeHandleIconSize` (`double`)
        *   `resizeHandleIconAlignment` (`Alignment`) - to support start/center/end.
    *   Refactor `PanelResizeHandle` widget to consume these new theme properties and constants.

### Phase 1: Create the Declarative API
1.  **Create `Panel` Widget:** Define the API surface. It should be a `StatelessWidget` (or `ProxyWidget`) that passes data down.
2.  **Create `PanelLayout` Wrapper:** Implement the logic to sync `children` list to `PanelLayoutController`.
    *   This allows us to keep the robust `PanelLayoutController` logic for now, just wrapping it in a nice declarative API.
3.  **Refactor `PanelArea`:** Make `PanelArea` private or internal, as `PanelLayout` becomes the public entry point.

### Phase 2: Deprecation (Safe Transition)
We will **not** remove the imperative API immediately.
1.  **Deprecate Manual Registration:** Mark `PanelLayoutController.registerPanel` as `@deprecated`.
2.  **Deprecate PanelController Constructor:** Mark `PanelController` constructor as `@deprecated` or "Internal Use Only".
3.  **Update Documentation:** Show the new `PanelLayout(children: [Panel(...)])` usage as the standard way.

### Phase 3: Migration of `SettingsPanel` (Example)
The `SettingsPanel` in `oilnet_app` currently relies on being manually added.
**New Usage:**
The `SettingsPanel` class itself remains focused on content (inputs, toggles).
It is instantiated inside the layout:
```dart
Panel(
  id: 'settings',
  mode: PanelMode.overlay,
  child: SettingsPanel(),
)
```
*Note: If `SettingsPanel` needs to close itself, it calls `Panel.of(context).close()`.*

## Next Steps
1.  Implement `Panel` widget structure in `panel_layout`.
2.  Implement `PanelLayout` widget with diffing logic.
3.  Verify with a simple test case.