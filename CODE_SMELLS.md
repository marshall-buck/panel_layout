# Code Smells Report - Panel Layout

This document tracks identified code smells and architectural concerns within the `panel_layout` project.

## 1. Abstraction Violation in `BasePanel` [FIXED]

The `BasePanel` class (an abstract base class) contained logic that explicitly checked for its subclasses (`InlinePanel`) and accessed properties specific to them (`rotateIcon`, `closingDirection`).

- **Location:** `lib/src/widgets/panels/base_panel.dart` (Method: `buildHeaderRow`)

- **Fix:** Introduced abstract getters `shouldRotate` and `effectiveClosingDirection` in `BasePanel`, implemented by `InlinePanel` and `OverlayPanel`. This removed the need for type checks and casting in the base class.

## 2. Magic Numbers & Unit Mixing in Resizing Logic

**Severity: High**
The `PanelResizing` class uses a hardcoded sensitivity factor (`0.01`) to convert pixel deltas into flex weight changes.

- **Location:** `lib/src/layout/panel_resizing.dart` (Method: `calculateResize`, Case 3)
- **Smell:** Mixing units (pixels vs. unitless flex) with arbitrary constants leads to inconsistent resizing behavior across different screen densities and aspect ratios.
- **Secondary Issue:** Flex resizing ignores `minSize` and `maxSize` constraints.

## 3. Long Method / Responsibility Bloat in `PanelLayout`

**Severity: Medium**
The `build` method of `_PanelLayoutState` is roughly 100 lines long and handles widget assembly, layout data preparation, resize handle generation, and sorting.

- **Location:** `lib/src/widgets/panel_layout.dart` (Method: `build`)
- **Smell:** Violates Single Responsibility Principle.

## 4. Ambiguous Controller Pattern

**Severity: Medium**
`PanelLayoutController` extends `ChangeNotifier` but functions as a command dispatcher. It never calls `notifyListeners()`.

- **Location:** `lib/src/controllers/panel_layout_controller.dart`
- **Smell:** Developers may attach listeners expecting state updates that will never trigger.

## 5. Build-Phase Runtime Errors

**Severity: Medium**
`_computeAxis` throws a `FlutterError` during the build phase if layout anchors are mismatched.

- **Location:** `lib/src/widgets/panel_layout.dart` (Method: `_computeAxis`)
- **Smell:** Configuration errors should ideally be caught during static analysis or initialization, rather than crashing the UI build loop.

## 6. Naive State Reconciliation

**Severity: Low**
`PanelStateManager.reconcile` aggressively purges state for panels not present in the current build pass.

- **Location:** `lib/src/state/panel_state_manager.dart`
- **Smell:** This prevents state persistence for panels that are toggled via conditional logic in the parent widget.

## 7. Redundant Strategy Instantiation

**Severity: Low**
`PanelLayoutDelegate.performLayout` instantiates layout strategies on every single frame/layout pass.

- **Location:** `lib/src/layout/panel_layout_delegate.dart`
- **Smell:** Excessive object allocation in a performance-critical path.
