# Panel Layout Refactor Plan: Declarative "Clean Slate" Architecture

**Goal:** Rebuild the package core to be "Widget-First". The `PanelLayout` widget and its children are the source of truth. Ephemeral state (dragging, collapsing) is managed internally by the layout engine, not by external imperative controllers.

## Core Philosophy
1.  **Configuration in Widgets:** Static properties (`minSize`, `anchor`, `child`) are defined in the widget tree.
2.  **Inheritance-First:** Users create panels by extending `BasePanel`.
3.  **State in Layout:** Dynamic properties (`currentSize`, `isCollapsed`) are managed by `PanelLayoutState`.
4.  **Controllers are Optional:** Used only for remote commands (e.g., "Open Sidebar"), not for defining structure.

## Refactor Steps

### Phase 0: Infrastructure (Complete)
*   [x] `constants.dart` for magic numbers.
*   [x] `ResizeHandleTheme` for clean styling.
*   [x] `PanelResizeHandle` updated to support legacy and new themes.

### Phase 1: The New Core (Complete)
*   [x] **Define `BasePanel` Widget:** The public API surface for inheritance.
*   [x] **Define `PanelRuntimeState` Model:** Internal class for tracking ephemeral state.
*   [x] **Create `PanelLayout` Widget:** The engine implementing `MultiChildLayoutDelegate` and state reconciliation.
*   [x] **Implement `PanelLayoutDelegate`:** Handles layout logic and handle injection.

### Phase 2: Cleanup & Verification (Complete)
*   [x] **Remove Legacy Code:** Deleted `PanelArea`, `PanelController` (legacy), and associated shims.
*   [x] **Verify Engine:** Implemented comprehensive tests (`panel_layout_test`, `panel_interaction_test`, `panel_anchoring_test`).
*   [x] **Migrate Consumer:** Updated `oilnet_app` to use the new declarative API via `app_panels.dart`.

## Status: COMPLETE
The package has been successfully refactored to a modern, declarative architecture.
