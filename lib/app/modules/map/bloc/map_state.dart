part of 'map_bloc.dart';

enum MapStatus { initial, loading, loaded, error }

class MapState extends Equatable {
  final List<DirectionData> directionData;
  final double? startLat;
  final double? startLng;
  final double? endLat;
  final double? endLng;
  final MapStatus status;
  final String error;

  const MapState({
    this.directionData = const [],
    this.startLat,
    this.startLng,
    this.endLat,
    this.endLng,
    this.status = MapStatus.initial,
    this.error = '',
  });

  MapState copyWith({
    List<DirectionData>? directionData,
    double? startLat,
    double? startLng,
    double? endLat,
    double? endLng,
    MapStatus? status,
    String? error,
  }) {
    return MapState(
      directionData: directionData ?? this.directionData,
      startLat: startLat ?? this.startLat,
      startLng: startLng ?? this.startLng,
      endLat: endLat ?? this.endLat,
      endLng: endLng ?? this.endLng,
      status: status ?? this.status,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
        directionData,
        startLat,
        startLng,
        endLat,
        endLng,
        status,
        error,
      ];
}
