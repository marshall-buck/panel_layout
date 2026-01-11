# Panel Layout

A pure Flutter, dependency-free, state-management-agnostic panel system.

`panel_layout` provides a robust layout engine for Flutter applications. It handles resizable panels, flexible content areas, and overlay panels (drawers) without imposing any specific state management solution (like BLoC or Provider) on your application.

## Features

-   **State Agnostic**: Works with `setState`, `Bloc`, `Riverpod`, `Provider`, or raw `ValueNotifier`.
-   **Resizable Panels**: Built-in drag handles for resizing fixed and flexible panels.
-   **Flexible Layouts**: Supports `Fixed` (pixels), `Flexible` (weight/height), and `Content` (intrinsic) sizing.
-   **Modes**:
    -   `Inline`: Panels flow in a Row/Column (pushing content).
    -   `Overlay`: Panels float on top (like drawers/modals).
-   **Granular Rebuilds**: Layout structure rebuilds only when necessary, keeping performance high.


