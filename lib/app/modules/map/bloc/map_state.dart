part of 'map_bloc.dart';

enum MapStatus { initial, loading, loaded, error }

class MapState extends Equatable {
  final List<DirectionData> directionData;
  final LatLng? currentLocation;
  final LatLng? destination;
  final MapStatus status;
  final String error;
  final MapLibreMapController? mapController;
  final bool isMapReady;

  const MapState({
    this.directionData = const [],
    this.currentLocation,
    this.destination,
    this.status = MapStatus.initial,
    this.error = '',
    this.mapController,
    this.isMapReady = false,
  });

  MapState copyWith({
    List<DirectionData>? directionData,
    LatLng? currentLocation,
    LatLng? destination,
    MapStatus? status,
    String? error,
    MapLibreMapController? mapController,
    bool? isMapReady,
  }) {
    return MapState(
      directionData: directionData ?? this.directionData,
      currentLocation: currentLocation ?? this.currentLocation,
      destination: destination ?? this.destination,
      status: status ?? this.status,
      error: error ?? this.error,
      mapController: mapController ?? this.mapController,
      isMapReady: isMapReady ?? this.isMapReady,
    );
  }

  MapState clearRoute() {
    return MapState(
      directionData: const [],
      currentLocation: currentLocation,
      destination: null,
      status: MapStatus.loaded,
      error: '',
      mapController: mapController,
      isMapReady: isMapReady,
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
        mapController,
        isMapReady,
      ];
}
