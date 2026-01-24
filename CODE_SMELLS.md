# Code Smells Report - Panel Layout

This document tracks identified code smells and architectural concerns within the `panel_layout` project.

## 1. Abstraction Violation in `BasePanel` [FIXED]

The `BasePanel` class (an abstract base class) contained logic that explicitly checked for its subclasses (`InlinePanel`) and accessed properties specific to them (`rotateIcon`, `closingDirection`).

- **Location:** `lib/src/widgets/panels/base_panel.dart` (Method: `buildHeaderRow`)

- **Fix:** Introduced abstract getters `shouldRotate` and `effectiveClosingDirection` in `BasePanel`, implemented by `InlinePanel` and `OverlayPanel`. This removed the need for type checks and casting in the base class.

## 2. Magic Numbers & Unit Mixing in Resizing Logic [FIXED]

**Severity: High**
The `PanelResizing` class uses a hardcoded sensitivity factor (`0.01`) to convert pixel deltas into flex weight changes.

- **Location:** `lib/src/layout/panel_resizing.dart` (Method: `calculateResize`, Case 3)
- **Fix:** Refactored `PanelLayout` to calculate a dynamic `pixelToFlexRatio` based on total available flexible space and total flex weight. This ratio is passed to `PanelResizing`, allowing for precise pixel-to-flex conversion and correct enforcement of `minSize`/`maxSize` constraints on flexible panels.

## 3. Long Method / Responsibility Bloat in `PanelLayout` [FIXED]

**Severity: Medium**
The `build` method of `_PanelLayoutState` is roughly 100 lines long and handles widget assembly, layout data preparation, resize handle generation, and sorting.

- **Location:** `lib/src/widgets/panel_layout.dart` (Method: `build`)
- **Fix:** Extracted logic into helper methods: `_createLayoutData`, `_calculatePixelToFlexRatio`, `_buildPanelWidgets`, and `_buildResizeHandles`. The `build` method now orchestrates these smaller, single-responsibility functions.

## 4. Ambiguous Controller Pattern [FIXED]

**Severity: Medium**
`PanelLayoutController` extended `ChangeNotifier` but functioned as a command dispatcher and never called `notifyListeners()`.

- **Location:** `lib/src/controllers/panel_layout_controller.dart`
- **Fix:** Removed `ChangeNotifier` extension. The class is now a pure command dispatcher, which aligns with its actual behavior and avoids misleading developers into attaching listeners. Added an explicit `dispose()` method.

## 5. Build-Phase Runtime Errors [FIXED]

**Severity: Medium**
`_computeAxis` throws a `FlutterError` during the build phase if layout anchors are mismatched.

- **Location:** `lib/src/widgets/panel_layout.dart` (Method: `_computeAxis`)
- **Fix:** Moved validation logic to `initState` and `didUpdateWidget` (renamed to `_validateAndComputeAxis`). Conflicting configurations now throw a custom `AnchorException` during widget initialization (Fail Fast), providing detailed information about the conflicting panels.

## 6. Naive State Reconciliation [FIXED]

**Severity: Low**
`PanelStateManager.reconcile` aggressively purges state for panels not present in the current build pass.

- **Location:** `lib/src/state/panel_state_manager.dart`
- **Smell:** This prevents state persistence for panels that are toggled via conditional logic in the parent widget.

## 7. Redundant Strategy Instantiation [FIXED]

**Severity: Low**
`PanelLayoutDelegate.performLayout` instantiates layout strategies on every single frame/layout pass.

- **Location:** `lib/src/layout/panel_layout_delegate.dart`
- **Fix:** Made `InlineLayoutStrategy` and `OverlayLayoutStrategy` constructors `const` (as they are stateless). Updated `PanelLayoutDelegate` to use `static const` instances of these strategies, eliminating object allocation during layout passes.
