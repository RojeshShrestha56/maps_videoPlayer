import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math' as math;
import '../bloc/map_bloc.dart';
import '../models/get_direction_model.dart';

class MapWidget extends StatefulWidget {
  const MapWidget({super.key});

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  MapLibreMapController? _mapController;
  bool _isMapReady = false;
  final String _apiKey = 'bpk.Lrp6rRIjOpVullIjTRPevEl-2uZPMgMQhnWnEHSxrGUG';

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeMap() async {
    context.read<MapBloc>().add(const InitializeMap());
    await _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    try {
      final status = await Permission.location.request();
      if (status.isGranted) {
        await _getCurrentLocation();
      } else {
        _showMessage('Location permission is required to use the map');
      }
    } catch (e) {
      _showMessage('Error requesting location permission');
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final location = LatLng(position.latitude, position.longitude);
      context.read<MapBloc>().add(UpdateCurrentLocation(location));

      if (_isMapReady && _mapController != null) {
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(location, 15.0),
        );
      }
    } catch (e) {
      _showMessage('Error getting location: ${e.toString()}');
    }
  }

  void _onMapCreated(MapLibreMapController controller) {
    setState(() {
      _mapController = controller;
      _isMapReady = true;
    });

    final currentLocation = context.read<MapBloc>().state.currentLocation;
    if (currentLocation != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(currentLocation, 15.0),
      );
    }
  }

  void _onMapTap(LatLng coordinates) {
    if (!_isMapReady) {
      _showMessage('Please wait for the map to initialize');
      return;
    }

    final currentLocation = context.read<MapBloc>().state.currentLocation;
    if (currentLocation == null) {
      _showMessage('Please wait for current location');
      return;
    }

    context.read<MapBloc>().add(UpdateDestination(coordinates));
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _clearMap() async {
    if (_mapController == null || !_isMapReady) return;

    await _mapController!.clearLines();
    await _mapController!.clearSymbols();
    context.read<MapBloc>().add(const ClearPath());

    final currentLocation = context.read<MapBloc>().state.currentLocation;
    if (currentLocation != null) {
      await _mapController!.addSymbol(
        SymbolOptions(
          geometry: currentLocation,
          iconImage: 'marker',
          iconSize: 1.5,
          iconColor: '#4CAF50',
        ),
      );
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(currentLocation, 15.0),
      );
    }
  }

  void _drawRoute(List<DirectionData> directionData) {
    if (_mapController == null || !_isMapReady || directionData.isEmpty) return;

    try {
      _mapController!.clearLines();
      final route = directionData.first;
      if (route.encodedPolyline.isEmpty) return;

      _mapController!.addLine(
        LineOptions(
          geometry: _decodePolyline(route.encodedPolyline),
          lineColor: '#2196F3',
          lineWidth: 4.0,
          lineOpacity: 0.8,
        ),
      );

      _fitRouteToScreen();
    } catch (e) {
      _showMessage('Error drawing route: ${e.toString()}');
    }
  }

  void _fitRouteToScreen() {
    final state = context.read<MapBloc>().state;
    if (state.currentLocation == null || state.destination == null) return;

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

    _mapController!.animateCamera(
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
    List<LatLng> poly = [];
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

      poly.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return poly;
  }

  void _updateMarkers() async {
    if (_mapController == null || !_isMapReady) return;

    await _mapController!.clearSymbols();
    final state = context.read<MapBloc>().state;

    if (state.currentLocation != null) {
      await _mapController!.addSymbol(
        SymbolOptions(
          geometry: state.currentLocation!,
          iconImage: 'marker',
          iconSize: 1.5,
          iconColor: '#4CAF50',
        ),
      );
    }

    if (state.destination != null) {
      await _mapController!.addSymbol(
        SymbolOptions(
          geometry: state.destination!,
          iconImage: 'marker',
          iconSize: 1.5,
          iconColor: '#F44336',
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MapBloc, MapState>(
      listener: (context, state) {
        if (state.status == MapStatus.loaded) {
          _updateMarkers();
          if (state.hasRoute) {
            _drawRoute(state.directionData);
          }
        } else if (state.status == MapStatus.error) {
          _showMessage(state.error);
        }
      },
      builder: (context, state) {
        return Stack(
          children: [
            MapLibreMap(
              onMapCreated: _onMapCreated,
              onMapClick: (_, coordinates) => _onMapTap(coordinates),
              initialCameraPosition: CameraPosition(
                target: state.currentLocation ??
                    const LatLng(27.717728723291803, 85.32784938812257),
                zoom: 12.0,
              ),
              styleString:
                  'https://api.baato.io/api/v1/styles/breeze?key=$_apiKey',
            ),
            if (state.status == MapStatus.loading)
              Container(
                color: Colors.black26,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            if (state.currentLocation == null)
              Container(
                color: Colors.black26,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Getting your location...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Positioned(
              right: 16,
              bottom: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton(
                    onPressed: _getCurrentLocation,
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.my_location, color: Colors.black),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    onPressed: _clearMap,
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.clear, color: Colors.black),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
