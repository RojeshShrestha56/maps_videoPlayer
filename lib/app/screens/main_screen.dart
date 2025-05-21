import 'package:flutter/material.dart';
import '../modules/map/views/map_widget.dart';
import '../modules/video/views/video_player_widget.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Baato Maps Demo'),
          bottom: const TabBar(
            tabs: [
              Tab(
                icon: Icon(Icons.map),
                text: 'Map',
              ),
              Tab(
                icon: Icon(Icons.video_library),
                text: 'Videos',
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            MapWidget(),
            VideoPlayerWidget(),
          ],
        ),
      ),
    );
  }
}
