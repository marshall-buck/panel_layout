# Refactor Plan: `panel_layout` to `flutter_panels`

## Objective

Transform the package from a "Layout Engine" identity to a "UI Augmentation" identity. The core logic remains the same, but the public API and branding will shift to emphasize "attaching" panels to an existing app rather than "building" a layout.

**New Package Name:** `flutter_panels`

## 1. High-Level Concept

Shift from "Building a layout" to "Attaching panels to a body".

* **Old:** `PanelLayout(children: [Sidebar, Body, Sidebar])`
* **New:** `PanelArea(body: Body, panels: [InlinePanel(...), OverlayPanel(...)])`

## 2. Terminology & Renaming

### Naming Decisions

The following names have been selected.

| Concept | Old Name | New Name | Reasoning |
| :--- | :--- | :--- | :--- |
| **Package** | `panel_layout` | `flutter_panels` | Broad, feature-centric. |
| **Root Widget** | `PanelLayout` | `PanelArea` | "Area" implies a designated region where panels live. |
| **Space-Taking Panel** | `InlinePanel` | **`InlinePanel`** | Kept original name. Describes participation in the layout flow. |
| **Floating Panel** | `OverlayPanel` | **`OverlayPanel`** | Kept original. Clearly indicates z-index layering. |
| **Delegate** | `PanelLayoutDelegate` | `PanelAreaDelegate` | Matches root widget. |

## 3. Public API Changes

### The Main Widget: `PanelArea`

Modify the constructor to explicitly separate the "user's content" from the "panels".

```dart
class PanelArea extends StatelessWidget {
  /// The main content of your application (e.g., your Scaffold, Map, Editor).
  /// This widget occupies all remaining space after InlinePanels take their share.
  final Widget body;

  /// A list of panels (Inline or Overlay) to attach to the body.
  final List<Panel> panels;

  final PanelController? controller;

  // Internally:
  // 1. Sort InlinePanels based on their 'anchor' property.
  // 2. Wrap 'body' in an internal adapter (flex: 1).
  // 3. Construct the final linear list: [...StartAnchored, Body, ...EndAnchored].
  // 4. Append OverlayPanels (floating).
}
```

### `InlinePanel` (Positioning via `anchor`)

Instead of relying on list order, `PanelArea` uses the panel's existing `anchor` property to determine its position relative to the `body`.

* **Logic**:
  * `PanelAnchor.left` or `PanelAnchor.top` -> Placed **before** the `body`.
  * `PanelAnchor.right` or `PanelAnchor.bottom` -> Placed **after** the `body`.
* **Conflict Resolution**: If multiple panels share an anchor (e.g., two `left` panels), their relative order in the `panels` list is preserved.

### `OverlayPanel`

* **Changes**: None. Name and logic retained.
* **Usage**: Anchored to the screen or specific widgets, floating above the `body` and `InlinePanel`s.

## 4. File Structure & Renaming Plan

```text
lib/
├── flutter_panels.dart  <-- renamed from panel_layout.dart
└── src/
    ├── widgets/
    │   ├── panel_area.dart <-- renamed from panel_layout.dart
    │   └── panels/
    │       ├── inline_panel.dart   <-- (Name retained)
    │       └── overlay_panel.dart <-- (Name retained)
    ├── controllers/
    │   └── panel_controller.dart <-- renamed from panel_layout_controller.dart
    └── ... (internal classes renamed correspondingly)
```

## 5. Documentation Overhaul

* **README.md**:
  * **New Title**: `flutter_panels`
  * **Pitch**: "Augment your UI with panels. Wrap your screen in a `PanelArea` to attach resizeable sidebars (`InlinePanel`) or floating tools (`OverlayPanel`)."
* **Doc Comments**: Update terminology to match `PanelArea`.

## 6. Execution Steps (Checklist)

### Phase 1: File & Class Renaming

1. [ ] **Rename Files**: Execute file system renames for the main entry points and widgets.
2. [ ] **Search & Replace**: Global replace of class names.
    * `PanelLayout` -> `PanelArea`
    * `PanelLayoutController` -> `PanelController`
3. [ ] **Update Pubspec**: Change name to `flutter_panels`.

### Phase 2: API Refactoring

1. [ ] **Refactor `PanelArea`**:
    * Update constructor to `({required Widget body, List<Panel> panels, ...})`.
    * Implement sorting logic based on `anchor` (Left/Top vs Right/Bottom).
2. [ ] **Update InlinePanel handling**: Ensure the engine correctly interprets the `anchor` for automatic placement.

### Phase 3: Cleanup & Verify

1. [ ] **Fix Exports**: Update `flutter_panels.dart`.
2. [ ] **Update Tests**: Refactor `test/` to use new API.
3. [ ] **Update Example**: Rewrite `example/` to showcase `PanelArea(body: ...)`.

## 7. Repository & Folder Renaming Guide

### Step 1: Rename Local Folder

```bash
cd ..
mv panel_layout flutter_panels
cd flutter_panels
```

### Step 2: Update Remote Repository

1. Rename repo to `flutter_panels` on GitHub.
2. `git remote set-url origin https://github.com/USERNAME/flutter_panels.git`

### Step 3: IDE Housekeeping

1. Close IDE.
2. Open `flutter_panels`.
3. Run `flutter clean` and `flutter pub get`.
