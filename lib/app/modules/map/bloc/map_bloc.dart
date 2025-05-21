import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../../../data/services/api_provider.dart';
import '../models/get_direction_model.dart';

part 'map_event.dart';
part 'map_state.dart';

class MapBloc extends Bloc<MapEvent, MapState> {
  final ApiProvider _apiProvider;

  MapBloc({required ApiProvider apiProvider})
      : _apiProvider = apiProvider,
        super(const MapState()) {
    on<InitializeMap>(_onInitializeMap);
    on<UpdateCurrentLocation>(_onUpdateCurrentLocation);
    on<UpdateDestination>(_onUpdateDestination);
    on<GetDirectionData>(_onGetDirectionData);
    on<ClearPath>(_onClearPath);
  }

  void _onInitializeMap(InitializeMap event, Emitter<MapState> emit) {
    emit(state.copyWith(status: MapStatus.initial));
  }

  void _onUpdateCurrentLocation(
    UpdateCurrentLocation event,
    Emitter<MapState> emit,
  ) {
    emit(state.copyWith(
      currentLocation: event.location,
      status: MapStatus.loaded,
    ));

    if (state.hasValidLocations) {
      add(GetDirectionData());
    }
  }

  void _onUpdateDestination(
    UpdateDestination event,
    Emitter<MapState> emit,
  ) {
    emit(state.copyWith(
      destination: event.location,
      status: MapStatus.loaded,
    ));

    if (state.hasValidLocations) {
      add(GetDirectionData());
    }
  }

  Future<void> _onGetDirectionData(
    GetDirectionData event,
    Emitter<MapState> emit,
  ) async {
    if (!state.hasValidLocations) return;

    try {
      emit(state.copyWith(status: MapStatus.loading));

      final response = await _apiProvider.getDirections(
        points: [
          [state.currentLocation!.latitude, state.currentLocation!.longitude],
          [state.destination!.latitude, state.destination!.longitude],
        ],
      );

      emit(state.copyWith(
        status: MapStatus.loaded,
        directionData: response,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: MapStatus.error,
        error: e.toString(),
      ));
    }
  }

  void _onClearPath(ClearPath event, Emitter<MapState> emit) {
    emit(state.clearRoute());
  }
}
