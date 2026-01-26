# Refactoring Report: Panel Layout Optimization

## Objectives

1. **Logic Extraction**: Extract complex layout calculation logic from `PanelLayout` into a dedicated `PanelLayoutEngine` or helper class to reduce the "God Class" problem.
2. **Performance Optimization**: Reduce excessive widget rebuilds and layout thrashing.
3. **State Management Refactoring**: Improve how state is managed and accessed.
4. **Maintainability**: Separate concerns between data, logic, and UI.

**Constraints**:

- Public API must remain unchanged.
- All existing tests must pass.

## Status

| Step | Description | Status |
| :--- | :--- | :--- |
| 1 | Create `refactoring_report.md` | **Completed** |
| 2 | Extract `PanelLayoutEngine` from `PanelLayout` | **Completed** |
| 3 | Integrate `PanelLayoutEngine` into `PanelLayout` | **Completed** |
| 4 | Refactor `PanelResizing` logic | **Completed** |
| 5 | Optimize `PanelLayoutDelegate` usage | **Completed** |
| 6 | Verify with Tests | **Completed** |

## Detailed Plan

### 1. Extract `PanelLayoutEngine`

Move the following private methods from `PanelLayout` to `lib/src/layout/panel_layout_engine.dart`:

- `_createLayoutData`
- `_calculatePixelToFlexRatio`
- `_validateAndComputeAxis`
- `_sortChildren` (helpers)
- **Status**: Done. Logic moved and integrated. Tests passed.

### 2. Optimize Rebuilds

- **Goal**: Prevent `PanelLayout` from rebuilding on every animation frame or drag update.
- **Strategy**:
  - Modify `PanelLayoutDelegate` to accept `PanelStateManager` and listen to it directly. It will generate `PanelLayoutData` on-the-fly inside `performLayout`.
  - Modify `PanelLayout` to remove `setState` from `_onStateChange` and `_handleResize`.
  - Wrap `PanelDataScope` and `AnimatedPanel` in `ListenableBuilder` (listening to `PanelStateManager`) so they update independently of the parent layout.
  - Calculate `pixelToFlexRatio` on-the-fly in `_handleResize` and `_onStateChange` instead of relying on build-time cached values.
- **Fixes Applied**:
  - Updated `PanelLayoutEngine.calculatePixelToFlexRatio` to use `effectiveSize` (animated size) instead of state flags, fixing stability issues during collapse animation.
  - Added logic to `PanelLayout._onStateChange` to trigger a rebuild ONLY when an animation completes, ensuring removed handles (for hidden panels) are cleaned up from the widget tree.

### 3. Verification

- Run `flutter test` after each significant change.
- **Result**: All tests passed.
