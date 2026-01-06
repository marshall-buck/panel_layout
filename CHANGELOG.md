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
