# 0.5.8

* **Breaking Change**: Removed `axis` parameter from `PanelLayout`. The layout axis is now automatically inferred from the `anchor` property of the `InlinePanel` children (Left/Right -> Horizontal, Top/Bottom -> Vertical).
* Added `ScopedTab` to example app to demonstrate nested, scoped configurations.
* Added `clipContent` to BasePanelWhat.
* Updated documentation to clarify `PanelLayoutConfig` scoping rules.
* **Internal Refactor**: Abstracted state management, resizing math, and layout strategies into dedicated, decoupled modules for better maintainability and testability.

## 0.5.7

* **Breaking Change**: Removed `PanelTheme` and `ResizeHandleTheme` widgets.
* **New Feature**: Introduced `PanelLayoutConfig` for centralized, type-safe configuration of layout styling and behavior.
* **API Change**: `PanelLayout` now accepts a `config` parameter (of type `PanelLayoutConfig`) to set global defaults for headers, decorations, resize handles, and animations.
* **Improvement**: `BasePanel` properties (like `headerPadding`, `iconSize`) now fall back to values in `PanelLayoutConfig` instead of hardcoded constants or separate themes.

## 0.5.6

* **UX Improvement**: Updated header icon placement logic to align with opening/closing direction conventions.
  * Panels anchored to the **Right** (closing to the Right) now display the toggle icon on the **Left** of the header (the opening side).
  * Panels anchored to the **Left**, **Top**, or **Bottom** display the toggle icon on the **Right** of the header.
* **Documentation**: Explicitly documented that `InlinePanel.icon` and `PanelToggleButton` expect a **Left-Pointing Chevron** (e.g., `Icons.chevron_left`) to ensure built-in rotation animations work correctly for all anchor directions.

## 0.5.5

* Internal: Made `PanelResizeHandle` internal.
* Fixed visual jumping of icons in panel headers.
