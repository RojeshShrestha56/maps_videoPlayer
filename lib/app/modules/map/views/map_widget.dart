import 'package:baato_maps/app/data/providers/network/api_endpoint.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import '../bloc/map_bloc.dart';

class MapWidget extends StatelessWidget {
  const MapWidget({super.key});

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<Uint8List> _loadDestinationImage() async {
    final ByteData data =
    await rootBundle.load('assets/images/destination.jpg');
    return data.buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MapBloc, MapState>(
      listener: (context, state) {
        if (state.status == MapStatus.error) {
          _showMessage(context, state.error);
        }
      },
      builder: (context, state) {
        return Stack(
          children: [
            MapLibreMap(
              onMapCreated: (controller) async {
                await controller.addImage(
                  "destination",
                  await _loadDestinationImage(),
                );
                context.read<MapBloc>()..add(MapControllerSet(controller));
              },
              onMapClick: (_, coordinates) {
                context.read<MapBloc>().add(UpdateDestination(coordinates));
              },
              initialCameraPosition: CameraPosition(
                target: state.currentLocation ??
                    const LatLng(27.717728723291803, 85.32784938812257),
                zoom: 15.0,
              ),
              styleString:
                  'https://api.baato.io/api/v1/styles/breeze?key=${ApiEndpoint.apiKey}',
              myLocationEnabled: true,
              myLocationRenderMode: MyLocationRenderMode.gps,
              myLocationTrackingMode: MyLocationTrackingMode.trackingGps,
            ),
            if (state.status == MapStatus.loading && state.currentLocation == null)
              Container(
                color: Colors.black26,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        state.error.isNotEmpty
                            ? state.error
                            : 'Getting your location...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (state.error.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<MapBloc>().add(const InitializeMap());
                          },
                          child: const Text('Try Again'),
                        ),
                      ],
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
                    onPressed: () {
                      if (state.currentLocation != null &&
                          state.mapController != null) {
                        state.mapController!.animateCamera(
                          CameraUpdate.newLatLngZoom(
                            state.currentLocation!,
                            15.0,
                          ),
                        );
                      } else {
                        context
                            .read<MapBloc>()
                            .add(const RequestLocationPermission());
                      }
                    },
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.my_location, color: Colors.black),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    onPressed: () {
                      if (state.mapController != null) {
                        state.mapController!.animateCamera(
                          CameraUpdate.zoomIn(),
                        );
                      }
                    },
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.add, color: Colors.black),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    onPressed: () {
                      if (state.mapController != null) {
                        state.mapController!.animateCamera(
                          CameraUpdate.zoomOut(),
                        );
                      }
                    },
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.remove, color: Colors.black),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    onPressed: () {
                      context.read<MapBloc>().add(const ClearPath());
                    },
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
