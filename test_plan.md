# Test Plan: Panel Layout Package

## 1. Objective
To implement a comprehensive suite of tests for the `panel_layout` package, ensuring robustness, stability, and correctness under various conditions. The goal is to achieve high code coverage and verify that panels function correctly in all circumstances (resizing, theming, serialization, layout constraints).

## 2. Testing Strategy
We will strictly follow Flutter package testing standards:
-   **Unit Tests (`test/unit/`)**: Focus on pure Dart logic, state management controllers, and data models.
-   **Widget Tests (`test/widget/`)**: Focus on UI components, rendering, interactions (gestures), and verify widget tree updates.

## 3. Test Coverage Plan

### 3.1. Data Models & State Logic (Unit Tests)

#### `panel_data.dart`
*   **Serialization**: Verify `toJson` and `fromJson` correctness.
*   **Immutability**: Test `copyWith` functionality.
*   **Equality**: Verify `==` and `hashCode` for state comparison.
*   **Defaults**: Ensure default values (e.g., `PanelState`) are correct.

#### `panel_controller.dart`
*   **State Management**: Test `value` updates (visibility, width, height).
*   **Logic**:
    *   Test `toggleVisibility()`.
    *   Test `width` / `height` setters respecting min/max constraints (if applicable in logic).
*   **Serialization**: Verify the controller can restore state from a map.

#### `panel_layout_controller.dart`
*   **Registry**: Test adding/retrieving panel controllers.
*   **Persistence**: Test `saveState` and `loadState` (simulating a database/prefs store).
*   **Reset**: Test resetting layout to default configuration.
*   **Notification**: Ensure listeners are notified when child panel controllers change.

#### `panel_theme.dart`
*   **Theme Data**: Test `PanelThemeData` defaults.
*   **Utilities**: Test `lerp` (linear interpolation) and `copyWith`.
*   **Equality**: Verify theme equality checks.

### 3.2. Widget Components (Widget Tests)

#### `panel_scope.dart`
*   **Propagation**: Verify `PanelScope.of(context)` returns the correct data.
*   **Updates**: Ensure dependents rebuild when `PanelLayoutController` notifies changes.

#### `layout_panel.dart`
*   **Rendering**: Verify the panel renders its child.
*   **Visibility**: Test that the panel disappears from the tree (or has 0 size) when `visible` is false.
*   **Sizing**: Verify strictly fixed sizing vs. flexible sizing behavior.
*   **Constraints**: Test behavior when constrained by parent (e.g., infinite vs finite constraints).

#### `panel_resize_handle.dart`
*   **Interaction**: Simulate drag gestures and verify the callback (`onResize`) is invoked with correct deltas.
*   **Visuals**: Verify the handle renders (hit test area vs visible area).
*   **Mouse Cursor**: Verify cursor changes on hover (e.g., `resizeColumn`, `resizeRow`).
*   **Theming**: Verify it respects `PanelThemeData` (e.g., hover colors).

#### `panel_area.dart`
*   **Layout**: Verify it correctly lays out children (columns/rows).
*   **Flexibility**: Test mixed `Flexible` and `Fixed` panels.
*   **Overflow**: Test behavior when panels exceed available space (scroll vs clip).
*   **Updates**: Verify layout refreshes when a child panel's controller changes size/visibility.

#### `panel_layout.dart`
*   **Integration**: Verify `PanelLayout` sets up the `PanelScope` and `PanelLayoutController`.
*   **Builder**: Test that the `builder` callback provides the correct controller.

## 4. Edge Cases & Stress Testing
*   **Zero Dimensions**: Panels with 0 width/height.
*   **Infinite Constraints**: Placing panels inside unbounded parents (e.g., `ListView` without size).
*   **Rapid Interaction**: Rapidly toggling visibility or dragging resize handles.
*   **Theme Switching**: Changing `PanelTheme` dynamically and ensuring visuals update.
*   **Empty Layouts**: `PanelArea` with no children.

## 5. Execution Order
1.  **Unit Tests**: `panel_data`, `panel_theme`, `panel_controller`, `panel_layout_controller`.
2.  **Basic Widget Tests**: `panel_scope`, `panel_resize_handle`, `layout_panel`.
3.  **Complex Widget Tests**: `panel_area`, `panel_layout`.
