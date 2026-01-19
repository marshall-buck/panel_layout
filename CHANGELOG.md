## 0.5.3

*   **Refactor (Breaking)**: Removed `toggleIcon`, `toggleIconSize`, and `toggleIconPadding`. Panels now use a single `icon` and `iconSize`.
*   **Refactor (Breaking)**: Collapsed rail size is now automatically calculated as `iconSize + 16.0`.
*   **Refactor (Breaking)**: Updated `PanelThemeData` properties to strictly match `BasePanel`:
    *   `headerTextStyle` -> `titleStyle`
    *   `panelDecoration` -> `panelBoxDecoration`
    *   `headerIconSize` -> `iconSize`
    *   `headerIconColor` -> `iconColor`
    *   Added `railDecoration`
*   **Refactor (Breaking)**: Removed `headerColor` and `headerBorder` from `BasePanel`. Use `headerDecoration`.

## 0.5.2

*   **Refactor (Breaking)**: Consolidated icon properties. `headerIcon` and `toggleIcon` are now a single `icon` property on `BasePanel`. The icon is automatically used in the header (if present) and the collapsed rail (for `InlinePanel`).
*   **Refactor (Breaking)**: Renamed/Consolidated styling properties for consistency:
    *   `headerTextStyle` -> `titleStyle`
    *   `headerIconSize` -> `iconSize`
    *   `headerIconColor` -> `iconColor`
*   **Refactor (Breaking)**: Simplified header decoration. `headerDecoration` is replaced by `headerColor` and `headerBorder`.
*   **Refactor (Breaking)**: Renamed "Toggle" properties to "Rail" in `InlinePanel` for clarity:
    *   `toggleIconAlignment` -> `railIconAlignment`
    *   `collapsedDecoration` -> `railDecoration`
    *   `rotateToggleIcon` -> `rotateIcon`
*   **Refactor (Breaking)**: Removed `headerAction`. `InlinePanel` header icons now toggle collapse by default, and `OverlayPanel` header icons close the panel by default.
*   **Docs**: Massive update to documentation comments across the entire public API for better clarity and developer experience.

## 0.5.1

*   **Breaking**: `PanelToggleButton` is now internal. It is automatically rendered by `InlinePanel` when `toggleIcon` is provided.
*   **Breaking**: Removed `collapsedChild` from `BasePanel`. If you need fully custom collapsed content, we recommend swapping your `child` widget based on the state from `PanelScope`.
*   **Feat**: Added built-in Header support to `BasePanel` (and subclasses). You can now easily add a `title`, `headerIcon`, and `headerAction` (like Close or Collapse).
*   **Feat**: Added `rotateToggleIcon` to `BasePanel` to optionally disable the automatic rotation of the toggle icon.
*   **Feat**: Added advanced toggle icon customization to `InlinePanel`, including `toggleIconSize`, `toggleIconPadding`, and `toggleIconAlignment`.
*   **Feat**: Added `PanelTheme` support for standard headers (`headerHeight`, `headerDecoration`, `headerTextStyle`, etc.).

## 0.5.0

*   **Breaking**: Removed `PanelMode`. Panels are now strictly typed as either `InlinePanel` or `OverlayPanel`.
*   **Breaking**: `BasePanel` is now `abstract`. You must instantiate or extend `InlinePanel` or `OverlayPanel`.
*   **Feat**: `InlinePanel` exposes linear layout properties (`flex`, `minSize`, `maxSize`, `resizable`) specifically for docked panels.
*   **Feat**: `OverlayPanel` exposes stack layout properties (`alignment`, `anchorLink`, `zIndex`) specifically for floating panels.
*   **Fix**: Fixed layout errors for content-sized panels by removing restrictive `Positioned.fill` constraints in `AnimatedPanel`.

## 0.4.1

*   **Feat**: Added support for "Mini Variants" (Collapsed Strips). Panels can now collapse to a small strip instead of disappearing completely.
*   **Feat**: Added `toggleIcon` property to `BasePanel`. Providing an icon automatically generates a clickable, rotating toggle button in the collapsed strip.
*   **Feat**: Added `collapsedChild` property to `BasePanel` for custom collapsed strip content.
*   **Feat**: Added `PanelToggleButton` widget. Automatically detects panel anchor and state to rotate its icon (e.g., a chevron) correctly.
*   **Fix**: Resolved layout overflow issues when collapsing panels with wide content by using an internal `Stack` and `OverflowBox` strategy.
*   **Fix**: Updated `PanelDataScope` to expose the panel's configuration (`BasePanel`) to descendants.

## 0.4.0

**MAJOR REFACTOR: Declarative "Widget-First" API**

This version introduces a complete overhaul of the package architecture, moving from an imperative controller-based system to a modern, declarative widget-centric system.

### Breaking Changes
*   **Removed `PanelArea`**: Replaced by the new `PanelLayout` widget.
*   **Removed Imperative `PanelController`**: Panel configuration is now handled via the `BasePanel` widget.
*   **Removed Model Classes**: `PanelSizing`, `PanelVisuals`, and `PanelConstraints` have been removed. Their properties are now flattened directly onto the `BasePanel` class.
*   **Removed Legacy Theme**: `PanelTheme` and `PanelThemeData` have been removed.
*   **Removed `PanelMode.detached`**: Panels are now either `inline` or `overlay`.
*   **Updated `PanelLayout`**: The constructor and behavior have changed completely. It now requires a `children` list of `BasePanel` objects.
*   **Updated `PanelLayout.of(context)`**: Now returns the new `PanelLayoutController` used for remote state manipulation.

### New APIs & Features
*   **`BasePanel`**: An abstract base class that users extend to create custom panels. It encapsulates both configuration (sizing, anchors) and content.
*   **`PanelLayout`**: The new declarative engine. It automatically manages panel life-cycles, state persistence (across rebuilds), and frame-perfect animations.
*   **`PanelLayoutController`**: A simplified remote control for programmatic actions like `toggleVisible(id)` or `setCollapsed(id, bool)`.
*   **`ResizeHandleTheme`**: A simplified, stateless styling API for customizing the appearance and hit-test area of resize handles.
*   **`PanelDataScope`**: An `InheritedWidget` that allows any descendant of a panel to access its runtime state (e.g., checking if it's currently collapsed or its animated size).
*   **`PanelRuntimeState`**: An immutable snapshot of a panel's current logical state.
*   **Automated Animations**: Smooth transitions for visibility and collapsing are now handled internally by the engine using a `TickerProvider`.
*   **LayerLink Support**: Improved integration for anchoring overlay panels to external widgets.
*   **Robust Stacking**: Native support for `zIndex` sorting to control paint order.

## 0.3.2

*   **Feat**: Added `zIndex` support to `PanelController` and `PanelLayoutController`.
*   **Fix**: Decoupled panel rendering order (Z-index) from the registration order in `PanelArea`. Panels are now sorted by `zIndex` before painting, allowing for explicit control over overlapping behavior (e.g., sliding from behind vs. sliding over).

## 0.3.1

*   **Fix**: Corrected the slide animation direction for anchored overlay panels. Relative overlays now correctly slide out from their anchor target instead of the screen edge.

## 0.3.0

*   **Feat**: Added `alignment`, `anchorLink`, and `crossAxisAlignment` to `PanelController` and `PanelLayoutController`.
*   **Feat**: Enabled arbitrary global positioning for overlay panels (e.g., Top Center).
*   **Feat**: Enabled anchoring overlay panels to arbitrary `LayerLink` targets (widgets outside the layout system).

## 0.2.0

*   **Breaking**: `registerPanel` now requires a `builder` function. This moves the definition of "what to render" into the registration phase, eliminating the need for a separate `panelBuilder` in `PanelArea`.
*   **Breaking**: `PanelArea` no longer accepts a `panelBuilder`. It now delegates to the builders registered with the `PanelController`.
*   **Refactor**: `PanelController` now holds a `builder` of type `Widget Function(BuildContext, PanelController)`.

## 0.1.0

*   **Feat**: Added `anchorPanel` support to `PanelController` and `PanelLayoutController`.
*   **Feat**: Implemented relative anchoring in `PanelArea`. Panels can now slide out from or float relative to other panels using `CompositedTransformFollower`.
*   **Refactor**: `PanelController` now maintains a `LayerLink` for geometry tracking.

## 0.0.1

* Initial release of the `panel_layout` package.