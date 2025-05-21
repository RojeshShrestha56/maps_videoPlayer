part of 'map_bloc.dart';

enum MapStatus { initial, loading, loaded, error }

class MapState extends Equatable {
  final List<DirectionData> directionData;
  final LatLng? currentLocation;
  final LatLng? destination;
  final MapStatus status;
  final String error;

  const MapState({
    this.directionData = const [],
    this.currentLocation,
    this.destination,
    this.status = MapStatus.initial,
    this.error = '',
  });

  MapState copyWith({
    List<DirectionData>? directionData,
    LatLng? currentLocation,
    LatLng? destination,
    MapStatus? status,
    String? error,
  }) {
    return MapState(
      directionData: directionData ?? this.directionData,
      currentLocation: currentLocation ?? this.currentLocation,
      destination: destination ?? this.destination,
      status: status ?? this.status,
      error: error ?? this.error,
    );
  }

  MapState clearRoute() {
    return MapState(
      directionData: const [],
      currentLocation: currentLocation,
      destination: null,
      status: MapStatus.loaded,
      error: '',
    );
  }

  bool get hasValidLocations => currentLocation != null && destination != null;

  bool get hasRoute => directionData.isNotEmpty;

  @override
  List<Object?> get props => [
        directionData,
        currentLocation,
        destination,
        status,
        error,
      ];
}
