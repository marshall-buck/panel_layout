# 0.5.10

* **Simplified API**: Users can now pass standard `Widget`s directly to `PanelLayout.children`.
  * Removed `UserContent` class.
  * Standard widgets are automatically wrapped in an internal adapter that fills available space (flex: 1).
  * Added `LayoutAdapter` mixin for marking widgets as panel participants (optional).
* **Breaking Change**: `UserContent` has been removed. Use standard widgets or extending classes with the `LayoutAdapter` mixin instead.

# 0.5.9

* **New Feature**: Introduced `UserContent` class.
  * An abstract base class for defining content-only panels that fill available space (`flex: 1`).
  * Designed to be extended by users to create specialized content regions without headers or default decorations.
  * Adjacent `UserContent` panels do not generate resize handles between them.
* **New Feature**: Added `onResizeStart` and `onResizeEnd` callbacks to `PanelLayout` to track user resize interactions.
* **Behavior Change**: Adjacent `UserContent` panels no longer show a resize handle, allowing for seamless content regions.

## 0.5.8

* **Breaking Change**: Removed `axis` parameter from `PanelLayout`. The layout axis is now automatically inferred from the `anchor` property of the `InlinePanel` children (Left/Right -> Horizontal, Top/Bottom -> Vertical).
* Added `ScopedTab` to example app to demonstrate nested, scoped configurations.
* Added `clipContent` to BasePanel.
* Updated documentation to clarify `PanelStyle` scoping rules.
* **Internal Refactor**: Abstracted state management, resizing math, and layout strategies into dedicated, decoupled modules for better maintainability and testability.
* **Bug Fix** Resize handle no longer shows when panel is not resizable.

## 0.5.7

* **Breaking Change**: Renamed `PanelLayoutConfig` to `PanelStyle`.
* **API Change**: `PanelLayout` now accepts a `style` parameter (of type `PanelStyle`) instead of `config`.
* **Breaking Change**: Removed `PanelTheme` and `ResizeHandleTheme` widgets.
* **New Feature**: Introduced `PanelStyle` for centralized, type-safe configuration of layout styling and behavior.
* **API Change**: `PanelLayout` now accepts a `style` parameter (of type `PanelStyle`) to set global defaults for headers, decorations, resize handles, and animations.
* **Improvement**: `BasePanel` properties (like `headerPadding`, `iconSize`) now fall back to values in `PanelStyle` instead of hardcoded constants or separate themes.

## 0.5.6

* **UX Improvement**: Updated header icon placement logic to align with opening/closing direction conventions.
  * Panels anchored to the **Right** (closing to the Right) now display the toggle icon on the **Left** of the header (the opening side).
  * Panels anchored to the **Left**, **Top**, or **Bottom** display the toggle icon on the **Right** of the header.
* **Documentation**: Explicitly documented that `InlinePanel.icon` and `PanelToggleButton` expect a **Left-Pointing Chevron** (e.g., `Icons.chevron_left`) to ensure built-in rotation animations work correctly for all anchor directions.

## 0.5.5

* Internal: Made `PanelResizeHandle` internal.
* Fixed visual jumping of icons in panel headers.
