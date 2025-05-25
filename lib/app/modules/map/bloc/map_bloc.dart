import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;
import 'dart:io' show Platform;
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
    on<MapDisposed>(_onMapDisposed);
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

      emit(state.copyWith(
        currentLocation: location,
        status: MapStatus.loaded,
      ));

      if (state.mapController != null && state.isMapReady) {
        try {
          await state.mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(location, 15.0),
          );
          add(const UpdateMapMarkers());
        } catch (_) {}
      }
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
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        int retryCount = 0;
        while (!serviceEnabled && retryCount < 3) {
          emit(state.copyWith(
            status: MapStatus.loading,
            error: 'Please enable location services to continue',
          ));
          await Future.delayed(const Duration(seconds: 1));
          serviceEnabled = await Geolocator.isLocationServiceEnabled();
          if (!serviceEnabled) {
            retryCount++;
            if (retryCount >= 3) {
              if (Platform.isAndroid) {
                await Geolocator.openLocationSettings();
              } else {
                await Geolocator.openAppSettings();
              }
              await Future.delayed(const Duration(seconds: 1));
              serviceEnabled = await Geolocator.isLocationServiceEnabled();
            }
          }
        }

        if (!serviceEnabled) {
          emit(state.copyWith(
            status: MapStatus.error,
            error:
                'Location services must be enabled to use the map. Please enable location and try again.',
          ));
          return;
        }
      }
      LocationPermission permission = await Geolocator.checkPermission();
      int permissionRetryCount = 0;

      while (
          permission == LocationPermission.denied && permissionRetryCount < 3) {
        emit(state.copyWith(
          status: MapStatus.loading,
          error: permissionRetryCount == 0
              ? 'Please allow location access to see your position on the map'
              : 'Location permission is needed to show your position. Please allow access.',
        ));

        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          permissionRetryCount++;
        }
      }

      if (permission == LocationPermission.denied) {
        emit(state.copyWith(
          status: MapStatus.error,
          error: 'Location permission is required. Please try again.',
        ));
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        emit(state.copyWith(
          status: MapStatus.error,
          error:
              'Location permission is permanently denied. Please enable it in app settings.',
        ));
        await Geolocator.openAppSettings();
        return;
      }
      Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      ).listen(
        (Position position) {
          add(UpdateCurrentLocation(
            LatLng(position.latitude, position.longitude),
          ));
        },
        onError: (e) {
          emit(state.copyWith(
            status: MapStatus.error,
            error: 'Error getting location updates',
          ));
        },
      );
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 3),
        );

        final location = LatLng(position.latitude, position.longitude);
        emit(state.copyWith(
          currentLocation: location,
          status: MapStatus.loaded,
          error: '',
        ));

        if (state.mapController != null && state.isMapReady) {
          try {
            await state.mapController!.updateMyLocationTrackingMode(
              MyLocationTrackingMode.tracking,
            );
            await state.mapController!.animateCamera(
              CameraUpdate.newLatLngZoom(location, 15.0),
            );
            add(const UpdateMapMarkers());
          } catch (_) {}
        }
      } catch (_) {
        emit(state.copyWith(
          status: MapStatus.loading,
          error: 'Getting your location...',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: MapStatus.error,
        error: 'Error accessing location',
      ));
    }
  }

  void _onMapDisposed(MapDisposed event, Emitter<MapState> emit) {
    emit(state.copyWith(
      mapController: null,
      isMapReady: false,
    ));
  }

  void _onMapControllerSet(MapControllerSet event, Emitter<MapState> emit) {
    try {
      if (state.mapController != null) {
        try {
          state.mapController!.clearSymbols();
          state.mapController!.clearLines();
        } catch (_) {}
      }

      emit(state.copyWith(
        mapController: event.controller,
        isMapReady: true,
        status: MapStatus.loaded,
      ));
      Future.microtask(() async {
        if (state.currentLocation != null) {
          try {
            await event.controller.animateCamera(
              CameraUpdate.newLatLngZoom(state.currentLocation!, 15.0),
            );
            add(const UpdateMapMarkers());

            if (state.destination != null && state.directionData.isNotEmpty) {
              add(const DrawRoute());
              add(const FitMapToRoute());
            }
          } catch (_) {}
        } else {
          add(const InitializeMap());
        }
      });
    } catch (e) {
      emit(state.copyWith(
        status: MapStatus.error,
        error: 'Error setting up map: ${e.toString()}',
      ));
    }
  }

  Future<void> _onUpdateCurrentLocation(
    UpdateCurrentLocation event,
    Emitter<MapState> emit,
  ) async {
    try {
      final bool isFirstLocation = state.currentLocation == null;
      emit(state.copyWith(
        currentLocation: event.location,
        status: MapStatus.loaded,
        error: '',
      ));

      if (state.mapController != null && state.isMapReady) {
        try {
          await state.mapController!.updateMyLocationTrackingMode(
            MyLocationTrackingMode.tracking,
          );
        } catch (_) {}
        add(const UpdateMapMarkers());
        if (isFirstLocation) {
          try {
            await state.mapController!.animateCamera(
              CameraUpdate.newLatLngZoom(event.location, 15.0),
            );
          } catch (_) {}
        } else if (state.destination == null) {
          try {
            await state.mapController!.animateCamera(
              CameraUpdate.newLatLng(event.location),
            );
          } catch (_) {}
        }
      }

      if (state.hasValidLocations) {
        add(const GetDirectionData());
      }
    } catch (_) {}
  }

  Future<void> _onUpdateDestination(
    UpdateDestination event,
    Emitter<MapState> emit,
  ) async {
    emit(state.copyWith(
      destination: event.location,
      status: MapStatus.loading,
    ));

    if (!state.hasValidLocations) {
      if (state.currentLocation == null) {
        add(const RequestLocationPermission());
      }
      return;
    }

    try {
      final response = await _apiProvider.getDirections(
        points: [
          [state.currentLocation!.latitude, state.currentLocation!.longitude],
          [event.location.latitude, event.location.longitude],
        ],
      );
      emit(state.copyWith(
        directionData: response,
        status: MapStatus.loaded,
      ));
      add(const UpdateMapMarkers());
      add(const DrawRoute());
    } catch (e) {
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
    if (state.mapController == null || !state.isMapReady) {
      return;
    }

    try {
      await state.mapController!.clearSymbols();
      if (state.currentLocation != null) {
        try {
          await state.mapController!.addSymbol(
            SymbolOptions(
              geometry: state.currentLocation!,
              iconImage: 'current_location',
              iconSize: 1.0,
            ),
          );
        } catch (_) {}
      }
      if (state.destination != null) {
        try {
          await state.mapController!.addSymbol(
            SymbolOptions(
              geometry: state.destination!,
              iconImage: 'destination',
              iconSize: 1.0,
            ),
          );
        } catch (_) {}
      }
    } catch (e) {
      emit(state.copyWith(
        status: MapStatus.error,
        error: 'Error updating map markers: ${e.toString()}',
      ));
    }
  }

  Future<void> _onDrawRoute(DrawRoute event, Emitter<MapState> emit) async {
    if (state.mapController == null ||
        !state.isMapReady ||
        state.directionData.isEmpty) {
      return;
    }

    try {
      await state.mapController!.clearLines();
      final route = state.directionData.first;
      if (route.encodedPolyline.isEmpty) {
        return;
      }

      try {
        final List<LatLng> points = _decodePolyline(route.encodedPolyline);
        await state.mapController!.addLine(
          LineOptions(
            geometry: points,
            lineColor: '#2196F3',
            lineWidth: 4.0,
            lineOpacity: 0.8,
          ),
        );
      } catch (_) {}
    } catch (e) {
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
    try {
      final bounds = LatLngBounds(
        southwest: LatLng(
          math.min(
              state.currentLocation!.latitude, state.destination!.latitude),
          math.min(
              state.currentLocation!.longitude, state.destination!.longitude),
        ),
        northeast: LatLng(
          math.max(
              state.currentLocation!.latitude, state.destination!.latitude),
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
    } catch (_) {}
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
