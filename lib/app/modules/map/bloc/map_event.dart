part of 'map_bloc.dart';

class MapEvent extends Equatable {
  const MapEvent();

  @override
  List<Object> get props => [];
}

final class InitializeMap extends MapEvent {
  const InitializeMap();

  @override
  List<Object> get props => [];
}

class GetDirectionData extends MapEvent {
  final double startLat;
  final double startLng;
  final double endLat;
  final double endLng;

  const GetDirectionData({
    required this.startLat,
    required this.startLng,
    required this.endLat,
    required this.endLng,
  });

  @override
  List<Object> get props => [startLat, startLng, endLat, endLng];
}

class ClearPath extends MapEvent {
  const ClearPath();

  @override
  List<Object> get props => [];
}
