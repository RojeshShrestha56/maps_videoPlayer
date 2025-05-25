import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;
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
    on<MapControllerSet>(_onMapControllerSet);
    on<UpdateMapMarkers>(_onUpdateMapMarkers);
    on<DrawRoute>(_onDrawRoute);
    on<RequestLocationPermission>(_onRequestLocationPermission);
    on<FitMapToRoute>(_onFitMapToRoute);
  }

  void _onInitializeMap(InitializeMap event, Emitter<MapState> emit) async {
    try {
      emit(state.copyWith(status: MapStatus.loading));

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          emit(state.copyWith(
            status: MapStatus.error,
            error:
                'Location services are disabled. Please enable them in settings.',
          ));
          return;
        }
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.unableToDetermine) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        emit(state.copyWith(
          status: MapStatus.error,
          error:
              'Location permission is required to show your location on the map.',
        ));
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        emit(state.copyWith(
          status: MapStatus.error,
          error:
              'Location permission is permanently denied. Please enable it in app settings.',
        ));
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final location = LatLng(position.latitude, position.longitude);
      add(UpdateCurrentLocation(location));
    } catch (e) {
      emit(state.copyWith(
        status: MapStatus.error,
        error: 'Error initializing map: ${e.toString()}',
      ));
    }
  }

  Future<void> _onRequestLocationPermission(
    RequestLocationPermission event,
    Emitter<MapState> emit,
  ) async {
    try {
      emit(state.copyWith(status: MapStatus.loading));
      await _getCurrentLocation(emit);
    } catch (e) {
      emit(state.copyWith(
        status: MapStatus.error,
        error: 'Error requesting location permission: ${e.toString()}',
      ));
    }
  }

  Future<void> _getCurrentLocation(Emitter<MapState> emit) async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        await Future.delayed(const Duration(seconds: 2));
        serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          emit(state.copyWith(
            status: MapStatus.error,
            error: 'Please enable location services to see your location.',
          ));
          return;
        }
      }

      // Double check permission before getting location
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.unableToDetermine) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          emit(state.copyWith(
            status: MapStatus.error,
            error:
                'Location permission denied. Please grant permission to see your location.',
          ));
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final location = LatLng(position.latitude, position.longitude);

      emit(state.copyWith(
        currentLocation: location,
        status: MapStatus.loaded,
      ));

      if (state.isMapReady && state.mapController != null) {
        await state.mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(location, 15.0),
        );
        add(const UpdateMapMarkers());
      }
    } catch (e) {
      emit(state.copyWith(
        status: MapStatus.error,
        error: 'Error getting location: ${e.toString()}',
      ));
    }
  }

  void _onMapControllerSet(MapControllerSet event, Emitter<MapState> emit) {
    emit(state.copyWith(
      mapController: event.controller,
      isMapReady: true,
    ));

    if (state.currentLocation != null) {
      event.controller.animateCamera(
        CameraUpdate.newLatLngZoom(state.currentLocation!, 15.0),
      );
      add(const UpdateMapMarkers());
    } else {
      add(const InitializeMap());
    }
  }

  Future<void> _onUpdateCurrentLocation(
    UpdateCurrentLocation event,
    Emitter<MapState> emit,
  ) async {
    emit(state.copyWith(
      currentLocation: event.location,
      status: MapStatus.loaded,
    ));

    if (state.mapController != null) {
      await state.mapController!.clearSymbols();

      await state.mapController!.addSymbol(
        SymbolOptions(
          geometry: event.location,
          iconImage: 'current-location',
          iconSize: 1.0,
        ),
      );

      if (state.destination != null) {
        await state.mapController!.addSymbol(
          SymbolOptions(
            geometry: state.destination!,
            iconImage: 'destination',
            iconSize: 1.0,
          ),
        );
      }

      await state.mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(event.location, 15.0),
      );
    }

    if (state.hasValidLocations) {
      add(const GetDirectionData());
    }
  }

  Future<void> _onUpdateDestination(
    UpdateDestination event,
    Emitter<MapState> emit,
  ) async {
    print('Handling UpdateDestination event');
    print('Current location: ${state.currentLocation}');
    print('New destination: ${event.location}');

    emit(state.copyWith(
      destination: event.location,
      status: MapStatus.loading,
    ));

    if (!state.hasValidLocations) {
      print(
          'Missing valid locations. Current: ${state.currentLocation}, Destination: ${state.destination}');
      if (state.currentLocation == null) {
        // Try to get current location if not available
        add(const RequestLocationPermission());
      }
      return;
    }

    try {
      print(
          'Getting directions from ${state.currentLocation} to ${event.location}');
      // Get directions first
      final response = await _apiProvider.getDirections(
        points: [
          [state.currentLocation!.latitude, state.currentLocation!.longitude],
          [event.location.latitude, event.location.longitude],
        ],
      );

      print('Got direction response: ${response.length} routes');
      emit(state.copyWith(
        directionData: response,
        status: MapStatus.loaded,
      ));

      // Then update markers and draw route
      add(const UpdateMapMarkers());
      add(const DrawRoute());
      add(const FitMapToRoute());
    } catch (e) {
      print('Error getting directions: $e');
      emit(state.copyWith(
        status: MapStatus.error,
        error: 'Error getting directions: ${e.toString()}',
      ));
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

      add(const DrawRoute());
      add(const FitMapToRoute());
    } catch (e) {
      emit(state.copyWith(
        status: MapStatus.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onClearPath(ClearPath event, Emitter<MapState> emit) async {
    if (state.mapController == null || !state.isMapReady) return;

    await state.mapController!.clearLines();
    await state.mapController!.clearSymbols();
    emit(state.clearRoute());

    add(const UpdateMapMarkers());

    if (state.currentLocation != null) {
      await state.mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(state.currentLocation!, 15.0),
      );
    }
  }

  Future<void> _onUpdateMapMarkers(
    UpdateMapMarkers event,
    Emitter<MapState> emit,
  ) async {
    if (state.mapController == null || !state.isMapReady) return;

    await state.mapController!.clearSymbols();

    if (state.currentLocation != null) {
      await state.mapController!.addSymbol(
        SymbolOptions(
          geometry: state.currentLocation!,
          iconImage: 'current-location',
          iconSize: 1.0,
        ),
      );
    }

    if (state.destination != null) {
      await state.mapController!.addSymbol(
        SymbolOptions(
          geometry: state.destination!,
          iconImage: 'destination',
          iconSize: 1.0,
        ),
      );
    }
  }

  Future<void> _onDrawRoute(DrawRoute event, Emitter<MapState> emit) async {
    if (state.mapController == null ||
        !state.isMapReady ||
        state.directionData.isEmpty) {
      print(
          'Cannot draw route: controller=${state.mapController != null}, isMapReady=${state.isMapReady}, hasDirections=${state.directionData.isNotEmpty}');
      return;
    }

    try {
      await state.mapController!.clearLines();
      final route = state.directionData.first;
      if (route.encodedPolyline.isEmpty) {
        print('Empty polyline received from API');
        return;
      }

      print('Decoding polyline: ${route.encodedPolyline}');
      final List<LatLng> points = _decodePolyline(route.encodedPolyline);
      print('Decoded ${points.length} points');

      await state.mapController!.addLine(
        LineOptions(
          geometry: points,
          lineColor: '#2196F3',
          lineWidth: 4.0,
          lineOpacity: 0.8,
        ),
      );
      print('Route line added to map');
    } catch (e) {
      print('Error drawing route: $e');
      emit(state.copyWith(
        status: MapStatus.error,
        error: 'Error drawing route: ${e.toString()}',
      ));
    }
  }

  void _onFitMapToRoute(FitMapToRoute event, Emitter<MapState> emit) {
    if (state.mapController == null ||
        !state.hasValidLocations ||
        !state.isMapReady) {
      return;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(
        math.min(state.currentLocation!.latitude, state.destination!.latitude),
        math.min(
            state.currentLocation!.longitude, state.destination!.longitude),
      ),
      northeast: LatLng(
        math.max(state.currentLocation!.latitude, state.destination!.latitude),
        math.max(
            state.currentLocation!.longitude, state.destination!.longitude),
      ),
    );

    state.mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        bounds,
        left: 50,
        right: 50,
        top: 50,
        bottom: 50,
      ),
    );
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }
}
