import 'package:equatable/equatable.dart';

/// A strongly-typed identifier for a panel in the layout system.
///
/// Using a strongly-typed ID prevents string-typing errors and ensures
/// clear identification of panels across the layout, controller, and state systems.
///
/// Example:
/// ```dart
/// static const mySidebar = PanelId('sidebar');
/// ```
class PanelId extends Equatable {
  /// Creates a [PanelId] with the given [value].
  const PanelId(this.value);

  /// The underlying string value of the ID.
  final String value;

  @override
  List<Object?> get props => [value];

  @override
  String toString() => 'PanelId($value)';
}