## 0.5.6

*   **UX Improvement**: Updated header icon placement logic to align with opening/closing direction conventions.
    *   Panels anchored to the **Right** (closing to the Right) now display the toggle icon on the **Left** of the header (the opening side).
    *   Panels anchored to the **Left**, **Top**, or **Bottom** display the toggle icon on the **Right** of the header.
*   **Documentation**: Explicitly documented that `InlinePanel.icon` and `PanelToggleButton` expect a **Left-Pointing Chevron** (e.g., `Icons.chevron_left`) to ensure built-in rotation animations work correctly for all anchor directions.

## 0.5.5

*   Internal: Made `PanelResizeHandle` internal.
*   Fixed visual jumping of icons in panel headers.