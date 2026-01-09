import 'package:equatable/equatable.dart';

/// A strongly-typed identifier for a panel in the layout system.
class PanelId extends Equatable {
  const PanelId(this.value);

  final String value;

  @override
  List<Object?> get props => [value];

  @override
  String toString() => 'PanelId($value)';
}
