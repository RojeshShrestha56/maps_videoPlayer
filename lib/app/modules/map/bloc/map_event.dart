part of 'map_bloc.dart';

class MapEvent extends Equatable {
  const MapEvent();

  @override
  List<Object?> get props => [];
}

class InitializeMap extends MapEvent {
  const InitializeMap();

  @override
  List<Object> get props => [];
}

class UpdateCurrentLocation extends MapEvent {
  final LatLng location;

  const UpdateCurrentLocation(this.location);

  @override
  List<Object> get props => [location];
}

class UpdateDestination extends MapEvent {
  final LatLng location;

  const UpdateDestination(this.location);

  @override
  List<Object> get props => [location];
}

class GetDirectionData extends MapEvent {
  const GetDirectionData();

  @override
  List<Object> get props => [];
}

class ClearPath extends MapEvent {
  const ClearPath();

  @override
  List<Object> get props => [];
}

class MapControllerSet extends MapEvent {
  final MapLibreMapController controller;

  const MapControllerSet(this.controller);

  @override
  List<Object> get props => [controller];
}

class UpdateMapMarkers extends MapEvent {
  const UpdateMapMarkers();

  @override
  List<Object> get props => [];
}

class DrawRoute extends MapEvent {
  const DrawRoute();

  @override
  List<Object> get props => [];
}

class RequestLocationPermission extends MapEvent {
  const RequestLocationPermission();

  @override
  List<Object> get props => [];
}

class FitMapToRoute extends MapEvent {
  const FitMapToRoute();

  @override
  List<Object> get props => [];
}
