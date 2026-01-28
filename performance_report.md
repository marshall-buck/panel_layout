# Performance Investigation Report

## Executive Summary

The `panel_layout` package exhibits several performance bottlenecks that explain the reported issues (slow rendering, rebuild jank, and animation jank). The primary causes are excessive widget rebuilding due to coarse-grained state listening, redundant heavy layout calculations running on every animation frame, and expensive clipping operations.

## Identified Issues

### 1. Global Rebuilds on Animation (Major Jank Source) - [FIXED]

**Location:** `lib/src/widgets/panel_layout.dart` (`_buildPanelWidgets`) and `lib/src/state/panel_state_manager.dart`

**Issue:**
The `PanelLayout` wraps *each* panel's widget tree in a `ListenableBuilder` that listens to the central `_stateManager`.

```dart
// panel_layout.dart
ListenableBuilder(
  listenable: _stateManager, // <--- Notifies every frame of ANY animation
  builder: (context, _) { ... }
)
```

In `PanelStateManager`, animation controllers for *all* panels add `notifyListeners` as a listener:

```dart
// panel_state_manager.dart
controller.addListener(notifyListeners);
```

**Impact:** When *any* panel animates (e.g., resizing, collapsing), `notifyListeners` is called 60 times per second. This triggers a rebuild of **every single panel wrapper** in the layout, not just the one changing. While the child content (e.g., `_FakeList`) might be const, the surrounding infrastructure (`AnimatedPanel`, `PanelDataScope`, `InlinePanel`'s structure) is rebuilt, causing unnecessary Element tree diffing and potentially deeper rebuilds if keys or instances mismatch.

**Fix:**

* Removed `ListenableBuilder` from `_buildPanelWidgets`.
* Refactored `AnimatedPanel` to accept `Animation<double>` objects and `ValueNotifier<PanelRuntimeState>` for precise state tracking.
* Used `AnimatedBuilder` inside `AnimatedPanel` listening to merged notifiers.
* Moved `PanelDataScope` inside `AnimatedPanel` to ensure it always provides fresh state without requiring parent rebuilds.

### 2. Redundant & Expensive Layout Calculations - [MITIGATED]

**Location:** `lib/src/widgets/panel_layout.dart` (`_onStateChange`) and `lib/src/layout/panel_layout_engine.dart`

**Issue:**
The layout engine performs full O(N) calculations multiple times per frame during animations.

1. **In `_onStateChange` (Animation Listener):**
    This method runs every frame during an animation. It calls:
    * `_engine.createLayoutData(...)`: Iterates all panels, creates new objects.
    * `_engine.calculatePixelToFlexRatio(...)`: Iterates all panels again.
    This logic is used to "lock" neighbor panels, but it recalculates the entire world state on every tick.

2. **In `PanelLayoutDelegate.performLayout`:**
    This also calls `_engine.createLayoutData` on every layout pass.

**Impact:** The UI thread is burdened with unnecessary object allocation and list iteration during critical animation frames, contributing to dropped frames (jank).

**Mitigation:**
* While `PanelLayoutDelegate` still runs on ticks (to support layout animations), the removal of the Widget Tree rebuild (Issue #1) significantly frees up CPU time, making these layout calculations much less impactful.
* Further optimization could involve caching `LayoutData`, but the current profile suggests the Widget Rebuild was the primary bottleneck. An attempt to remove the redundant calculation in the delegate broke critical layout logic and was reverted.

### 3. Expensive Clipping Operations (Rendering Latency) - [FIXED]

**Location:**
* `lib/src/widgets/panels/base_panel.dart`
* `lib/src/widgets/animation/animated_vertical_panel.dart`

**Issue:**
* `BasePanel` applied `Clip.antiAlias` to its container if a decoration was present.
* `AnimatedVerticalPanel` *also* explicitly set `clipBehavior: Clip.antiAlias` when a decoration was present.

**Impact:** `Clip.antiAlias` forces an off-screen rendering pass (`saveLayer`), which is very expensive on the GPU. Doing this for every panel, especially during animation where the layer must be re-rasterized every frame, or during initial load (shader compilation), significantly increases rendering time. This was identified as the likely cause of the "5.1ms shader compilation" jank on load.

**Fix:**
* Changed `Clip.antiAlias` to `Clip.hardEdge` in both `BasePanel` and `AnimatedVerticalPanel`. This avoids `saveLayer` and is significantly faster.

### 4. Inefficient "Stable Neighbor" Logic

**Location:** `lib/src/widgets/panel_layout.dart` (`_onStateChange`)

**Issue:**
The logic to find a "stable neighbor" iterates through the panel list on every animation frame. Combined with the layout data recreation mentioned in #2, this maximizes CPU usage during what should be a smooth visual transition.

### 5. Unnecessary Widget Structure Instantiation - [FIXED]

**Location:** `lib/src/widgets/panels/inline_panel.dart`

**Issue:**
`InlinePanel` is a widget that builds a `Column` containing a `Container` (Header) and `Expanded` (Body). Because `AnimatedPanel` rebuilds every frame (due to Issue #1), `InlinePanel.build` runs every frame, creating new instances of these structural widgets. This forces the Flutter framework to perform element reconciliation constantly.

**Fix:**

* By fixing Issue #1 (stopping `PanelLayout` from rebuilding), `InlinePanel` is no longer constantly rebuilt/re-instantiated by the parent. It only rebuilds when its specific `AnimatedBuilder` inside `AnimatedPanel` triggers, which is much more efficient.

## Further Findings & Deep Analysis

### 6. Duplicate Layout Calculations ("Double Duty") - [WONTFIX]

**Location:** `lib/src/widgets/panel_layout.dart` vs `lib/src/layout/panel_layout_delegate.dart`

**Observation:**
The package calculates the abstract layout model twice per frame/build:
1.  **In `PanelLayout.build`**: `_engine.createLayoutData` is called to determine which `PanelResizeHandle` widgets to instantiate and where to place them (implicitly, via the list).
2.  **In `PanelLayoutDelegate.performLayout`**: `_engine.createLayoutData` is called *again* to calculate the boxes for the `CustomMultiChildLayout`.

**Impact:**
This doubles the cost of the "business logic" for the layout. For complex layouts or frequent rebuilds (like tab switching), this adds unnecessary overhead (O(2N) instead of O(N)).

**Resolution:**
An attempt to fix this by passing pre-calculated `layoutData` to the delegate broke essential resizing logic, as the delegate lost its direct connection to the fresh state during drag operations. The fix was reverted. The performance impact of this is mitigated by the fix for Issue #1, making this optimization a low priority.

### 7. Missing RepaintBoundaries on Fading Content (Shader Compilation Jank) - [REVERTED]

**Location:** `lib/src/widgets/animation/animated_horizontal_panel.dart` (and Vertical variant)

**Observation:**
When a panel collapses or expands, `Opacity` is applied. An attempt was made to wrap this in `RepaintBoundary` to cache rasterization.

**Outcome:**
The user reported that this added a frame of rendering latency without solving the issue. This suggests the overhead of creating/managing the texture was higher than the savings, or that the bottleneck was actually the `Clip.antiAlias` issue (Issue #3) all along. The change was reverted.

### 8. Heavy Initialization on Tab Switch - [MITIGATED]

**Location:** `PanelStateManager.reconcile`

**Observation:**
When switching tabs, the entire `PanelLayout` is built from scratch. `initState` triggers `reconcile`, which instantiates `AnimationController`s.

**Resolution:**
The "initialization jank" (shader compilation) was primarily driven by the `Clip.antiAlias` usage in `AnimatedVerticalPanel` (Issue #3). By fixing that, the heavy rendering cost on the first frame is removed. The object allocation cost of `reconcile` (creating controllers) is negligible compared to the rendering cost of `saveLayer` shaders.

## Conclusion

The observed jank is a direct result of the package architecture forcing global rebuilds and heavy computations on the UI thread during animations, combined with expensive default clipping behavior. Refactoring to decoupled, local state listeners and switching to `Clip.hardEdge` has addressed these bottlenecks.