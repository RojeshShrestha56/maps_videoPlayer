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
