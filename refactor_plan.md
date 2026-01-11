# Panel Layout Refactor Plan: Declarative "Clean Slate" Architecture

**Goal:** Rebuild the package core to be "Widget-First". The `PanelLayout` widget and its children are the source of truth. Ephemeral state (dragging, collapsing) is managed internally by the layout engine, not by external imperative controllers.

## Core Philosophy
1.  **Configuration in Widgets:** Static properties (`minSize`, `anchor`, `child`) are defined in the widget tree.
2.  **Inheritance-First:** Users create panels by extending `BasePanel`.
3.  **State in Layout:** Dynamic properties (`currentSize`, `isCollapsed`) are managed by `PanelLayoutState`.
4.  **Controllers are Optional:** Used only for remote commands (e.g., "Open Sidebar"), not for defining structure.

## Architecture Overview

### 1. `BasePanel` Widget (Configuration)
A stateless configuration object that users extend.
```dart
class SidebarPanel extends BasePanel {
  SidebarPanel() : super(
    id: 'sidebar',
    width: 250,
    minSize: 100,
    anchor: PanelAnchor.left,
    child: SidebarContent(),
  );
}
```

### 2. `PanelLayout` Widget (The Engine)
A stateful orchestrator.
*   **Input:** `children` (List of `BasePanel`).
*   **State:** `Map<PanelId, PanelState>`.
    *   `PanelState` holds: `size` (user-resized), `visible`, `collapsed`.
*   **Logic:**
    *   Reconciles `children` with `PanelState` (e.g., preserves `size` if `BasePanel` re-appears).
    *   Handles resize gestures directly.
    *   Computes layout using `CustomMultiChildLayout`.

### 3. `PanelController` (The Remote)
A simplified interface for commanding the layout.
*   `controller.toggle(id)`
*   `controller.resize(id, size)`

## Refactor Steps

### Phase 0: Infrastructure (Complete)
*   [x] `constants.dart` for magic numbers.
*   [x] `ResizeHandleTheme` for clean styling.
*   [x] `PanelResizeHandle` updated to support legacy and new themes.

### Phase 1: The New Core
1.  **Define `BasePanel` Widget:** The public API surface for inheritance.
2.  **Define `PanelRuntimeState` Model:** Internal class for tracking ephemeral state.
3.  **Create `PanelLayout` Widget:**
    *   Implement state reconciliation (Widget Config + Internal State = Render Props).
    *   Implement `MultiChildLayoutDelegate` (ported/refactored from `PanelArea` logic).
    *   Implement resize logic (modifying `PanelState`).

### Phase 2: The Bridge (Compatibility)
To support `oilnet_app` and existing users:
1.  **Reimplement `PanelArea` (Legacy):**
    *   Make it a wrapper around `PanelLayout`.
    *   Convert `PanelController` list -> `List<BasePanel>` widgets.
    *   Sync `PanelLayout` state changes back to `PanelController` (two-way binding).
2.  **Deprecate Imperative API:** Mark controllers as legacy.

### Phase 3: Migration & Cleanup
1.  Migrate `oilnet_app` to use `PanelLayout` directly.
2.  Remove the Legacy Bridge (`PanelArea`, old `PanelController`).
3.  Final cleanup.

## Detailed Tasks (Phase 1)
1.  Create `lib/src/widgets/base_panel.dart` (The Config Widget).
2.  Create `lib/src/state/panel_runtime_state.dart` (The Runtime State).
3.  Create `lib/src/widgets/panel_layout.dart` (The Engine).
4.  Refactor layout logic: Extract the pure math from `PanelArea` into a shared `LayoutAlgorithm` or pure Delegate that consumes abstract data, so it can be used by both New and Legacy widgets.