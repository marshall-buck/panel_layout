# Issue: Panel Z-Ordering Dependence on Registration Order

**Status:** Open  
**Priority:** Medium  
**Labels:** `bug`, `enhancement`, `ux`

## Description

The current implementation of `PanelArea` tightly couples the rendering order (Z-index) of panels to the order of the `panelIds` list provided by the consumer. This forces the application layer to manually manage the list order to achieve specific visual stacking effects, which is brittle and unintuitive.

In complex layouts involving overlays and anchored panels, consumers often need specific "stacking intentions" (e.g., an overlay sliding out from *behind* its anchor vs. floating *on top*). Currently, the only way to achieve "sliding from behind" is to ensure the overlay's ID appears *before* the anchor's ID in the `panelIds` list. This exposes implementation details (painting order) to the API consumer.

## Reproduction Case

Context: `oilnet_app`
Scenario: `settings_change_panel` is anchored to `settings_panel`.

1. **Setup:**
   - `settings_panel` (Inline/Overlay) is the main parent.
   - `settings_change_panel` is an overlay anchored to `settings_panel`.
   - Intention: `settings_change_panel` should appear to slide out from *behind* `settings_panel`.

2. **Current Code (Bug):**
   ```dart
   PanelArea(
     panelIds: [
       ...,
       PanelId(AppMagic.settingsPanelId),        // Rendered 4th
       PanelId(AppMagic.settingsChangePanelId),  // Rendered 5th (On Top)
     ],
   )
   ```
   **Result:** The change panel renders on top of the settings panel. When animating "out", it slides over the face of the settings panel instead of tucking behind it.

3. **Workaround (Fragile):**
   Reordering the list in the consumer app:
   ```dart
   PanelArea(
     panelIds: [
       ...,
       PanelId(AppMagic.settingsChangePanelId),  // Rendered 4th (Behind)
       PanelId(AppMagic.settingsPanelId),        // Rendered 5th (On Top)
     ],
   )
   ```

## Expected Behavior

The consumer should not be responsible for manually sorting `panelIds` to control Z-index. The `panel_layout` package should handle this logic, respecting the hierarchical relationships or explicit configuration of the panels.

## Proposed Solutions

### 1. Explicit Stacking Context (Recommended)
Add a `zIndex` or `priority` integer to `PanelController` (or `PanelData`). `PanelArea` should sort panels by this index before rendering.

### 2. Relative Stacking Configuration
Add a property to `PanelMode.overlay` or a new `OverlayPolicy` that defines the stacking behavior relative to the anchor.
- `stacking: PanelStacking.front` (Default)
- `stacking: PanelStacking.behind`

### 3. Automatic Dependency Sorting
`PanelArea` could detect anchor relationships. If Panel B is anchored to Panel A, the layout engine could determine the optimal default order. However, this is ambiguous (does "anchored to" mean "child of" or "sibling of"?), so explicit configuration (Option 2) is likely safer.

## Impact
- **Developer Experience:** Poor. Developers must trial-and-error list ordering.
- **Maintenance:** High risk of regression. Adding a new panel requires careful insertion into the correct index of the global list.
