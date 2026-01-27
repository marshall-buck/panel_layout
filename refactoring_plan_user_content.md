# Refactoring Plan: Simplified User Content API

## 1. Problem Statement

The current `UserContent` API is too rigid and intrusive.

- **Issue 1:** It forces the user to extend a specific class (`UserContent`).
- **Issue 2:** It mandates passing package-specific properties (like `PanelId`) through the user's widget constructor.
- **Issue 3:** It requires overriding a custom `buildContent` method instead of the standard `build`.
- **Goal:** Allow users to use "completely normal widgets" in the `PanelLayout` list. Configuration (like flex) should be intrinsic to the widget (via mixin or extension) and not passed as parameters during instantiation.

## 2. Proposed Solution

### A. `PanelLayout` Updates

- **Type Change:** Change `children` from `List<BasePanel>` to `List<Widget>`.
- **Initialization Logic:**
  - Iterate through the provided `children`.
  - If a child is a `BasePanel` (e.g., `InlinePanel`, `OverlayPanel`), use it as-is.
  - If a child is a standard `Widget`, wrap it internally in an `InternalLayoutAdapter`.

### B. The `LayoutAdapter` Mixin

Introduce a marker mixin that users can optionally apply to their widgets to indicate they are part of the panel system (e.g. for future extensibility), though strictly speaking, any widget will work.

```dart
mixin LayoutAdapter on Widget {
  // No properties needed.
}
```

### C. Internal Wrapper (`InternalLayoutAdapter`)

A hidden, internal class used to bridge standard widgets into the `PanelLayout` system. **Important: This is NOT a panel.** It is a passive participant that allows the layout engine to manage the space occupied by standard widgets.

- **Responsibility:**
  - Wraps the user's `Widget`.
  - **Auto-ID:** Always generates an arbitrary `PanelId` (e.g., `auto_panel_0`, `auto_panel_1`).
  - **Flex:** Always defaults to `1.0`. The user cannot override this.
  - **Rendering:** Renders the child widget directly with no headers, decorations, or extra UI.
  - **Performance:** Ensure that the `InternalLayoutAdapter` (or the layout engine's wrapper) does not cause unnecessary rebuilds of the user's content widget during layout transitions or sibling resizing. It should ideally behave as a pass-through that preserves the widget's subtree.

### D. Layout & Anchoring

- **Resize Handles:** `InternalLayoutAdapter`s never have resize handles between them. They are purely content fillers that share space according to their flex values.
- **Resizing Reaction:** They do not initiate resizing. Instead, they react passively to the size changes of adjacent `InlinePanel`s.

## 3. User Experience Comparison

**Current (Bad):**

```dart
class MyEditor extends UserContent {
  MyEditor({required super.id}); // Must pass ID

  @override
  Widget buildContent(BuildContext context) { // Custom build method
    return Container(...);
  }
}

// Usage
PanelLayout(
  children: [
    MyEditor(id: PanelId('editor')), // Must instantiate with ID
  ]
)
```

**Proposed (Good):**

```dart
class MyEditor extends StatelessWidget with LayoutAdapter {

  @override
  Widget build(BuildContext context) { // Standard build
    return Container(...);
  }
}

// Usage
PanelLayout(
  children: [
    MyEditor(), // Clean instantiation! No IDs, no package props.
    Text('Simple Widget'), // Even this works (default flex=1)
  ]
)
```

## 4. Implementation Steps

1. **Define `LayoutAdapter` Mixin** in `lib/src/widgets/panels/layout_adapter.dart`.
2. **Create `InternalLayoutAdapter`** in `lib/src/widgets/internal/internal_layout_adapter.dart` (extending `InlinePanel` internally to satisfy the layout engine, but stripped of all panel features).
3. **Update `PanelLayout`** to accept `List<Widget>` and perform the wrapping/adaptation.
4. **Remove `UserContent`** entirely and update all internal references.
5. **Add Tests** to verify the new API, arbitrary ID generation, flex behavior, and handle-less layout between adapters.
6. **Update Example App** to reflect the new API.
