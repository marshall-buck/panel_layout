import 'package:equatable/equatable.dart';

class PanelConstraints extends Equatable {
  const PanelConstraints({
    this.minSize = 0.0,
    this.maxSize = double.infinity,
    this.collapsedSize = 48.0,
  });

  final double minSize;
  final double maxSize;
  final double collapsedSize;

  @override
  List<Object?> get props => [minSize, maxSize, collapsedSize];
}
