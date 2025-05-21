import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../bloc/map_bloc.dart';
import '../models/get_direction_model.dart';

class MapWidget extends StatefulWidget {
  const MapWidget({super.key});

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  MapLibreMapController? _mapController;
  LatLng? _startPoint;
  LatLng? _endPoint;
  bool _isStartPointSet = false;
  bool _isMapReady = false;
  final String _apiKey = 'bpk.Lrp6rRIjOpVullIjTRPevEl-2uZPMgMQhnWnEHSxrGUG';
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void dispose() {
    _isDisposed = true;
    if (_mapController != null) {
      _mapController!.dispose();
      _mapController = null;
    }
    super.dispose();
  }

  Future<void> _initializeMap() async {
    if (_isDisposed) return;
    context.read<MapBloc>().add(const InitializeMap());
    await _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final status = await Permission.location.request();
      if (status.isGranted) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        setState(() {
          _startPoint = LatLng(position.latitude, position.longitude);
          _isStartPointSet = true;
        });
        if (_isMapReady && _mapController != null) {
          await _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(_startPoint!, 15.0),
          );
          _addMarkers();
        }
      } else {
        debugPrint('Location permission denied');
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  void _onMapTap(LatLng coordinates) {
    if (!_isStartPointSet || !_isMapReady) return;

    setState(() {
      _endPoint = coordinates;
    });

    _addMarkers();
    _fetchDirections();
  }

  void _fetchDirections() {
    if (_startPoint == null || _endPoint == null) return;

    context.read<MapBloc>().add(GetDirectionData(
          startLat: _startPoint!.latitude,
          startLng: _startPoint!.longitude,
          endLat: _endPoint!.latitude,
          endLng: _endPoint!.longitude,
        ));
  }

  void _onMapCreated(MapLibreMapController controller) {
    if (_isDisposed) return;
    setState(() {
      _mapController = controller;
      _isMapReady = true;
    });

    if (_startPoint != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_startPoint!, 15.0),
      );
      _addMarkers();
    }
  }

  Future<void> _addMarkers() async {
    if (_mapController == null || !_isMapReady || _isDisposed) return;

    try {
      await _mapController!.clearSymbols();

      if (_startPoint != null) {
        await _mapController!.addSymbol(
          SymbolOptions(
            geometry: _startPoint!,
            iconImage: 'marker',
            iconSize: 1.5,
          ),
        );
      }

      if (_endPoint != null) {
        await _mapController!.addSymbol(
          SymbolOptions(
            geometry: _endPoint!,
            iconImage: 'marker',
            iconSize: 1.5,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error adding markers: $e');
    }
  }

  void _drawRoute(List<DirectionData> directionData) {
    if (_mapController == null ||
        !_isMapReady ||
        _isDisposed ||
        directionData.isEmpty) return;

    try {
      _mapController!.clearLines();
      final route = directionData.first;
      if (route.encodedPolyline.isEmpty) return;

      _mapController!.addLine(
        LineOptions(
          geometry: _decodePolyline(route.encodedPolyline),
          lineColor: '#FF0000',
          lineWidth: 3.0,
        ),
      );
    } catch (e) {
      debugPrint('Error drawing route: $e');
    }
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

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MapBloc, MapState>(
      listener: (context, state) {
        if (state.status == MapStatus.loaded) {
          _drawRoute(state.directionData);
        }
      },
      builder: (context, state) {
        return Stack(
          children: [
            MapLibreMap(
              onMapCreated: _onMapCreated,
              onMapClick: (_, LatLng coordinates) => _onMapTap(coordinates),
              initialCameraPosition: CameraPosition(
                target: _startPoint ??
                    const LatLng(27.717728723291803, 85.32784938812257),
                zoom: 12.0,
              ),
              styleString:
                  'https://api.baato.io/api/v1/styles/breeze?key=$_apiKey',
            ),
            if (state.status == MapStatus.loading)
              const Center(
                child: CircularProgressIndicator(),
              ),
            if (state.status == MapStatus.error)
              Center(
                child: Text(
                  state.error,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            if (!_isStartPointSet)
              const Center(
                child: Text(
                  'Waiting for location permission...',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            Positioned(
              right: 16,
              bottom: 16,
              child: FloatingActionButton(
                onPressed: () {
                  if (_mapController != null) {
                    _mapController!.clearLines();
                    _mapController!.clearSymbols();
                    setState(() {
                      _endPoint = null;
                    });
                    context.read<MapBloc>().add(const ClearPath());
                  }
                },
                backgroundColor: Colors.white,
                child: const Icon(Icons.clear, color: Colors.black),
              ),
            ),
          ],
        );
      },
    );
  }
}
