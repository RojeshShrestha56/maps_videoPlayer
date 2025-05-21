import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import '../bloc/video_bloc.dart';
import '../widgets/video_setup_widget.dart';

class VideoPlayerWidget extends StatefulWidget {
  const VideoPlayerWidget({super.key});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<VideoBloc>().add(const InitializeVideo());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      context.read<VideoBloc>().add(const SavePlaybackState());
    } else if (state == AppLifecycleState.resumed) {
      context.read<VideoBloc>().add(const RestorePlaybackState());
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VideoBloc, VideoState>(
      listener: (context, state) {
        if (state.status == VideoStatus.error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.error),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        return Column(
          children: [
            // Video Setup Widget
            const VideoSetupWidget(),

            // Video Player Content
            Expanded(
              child: _buildVideoContent(state),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVideoContent(VideoState state) {
    if (state.status == VideoStatus.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == VideoStatus.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              state.error,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                context.read<VideoBloc>().add(const InitializeVideo());
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final video = state.currentVideo;
    if (video == null) return const SizedBox.shrink();

    final controller = context.read<VideoBloc>().controller;
    if (controller == null) return const SizedBox.shrink();

    return Column(
      children: [
        // Video Title with sequence indicator
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  video.title,
                  style: Theme.of(context).textTheme.titleLarge,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'Video ${state.currentVideoIndex + 1}/3',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),

        // Video Player
        AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(controller),
              // Play/Pause overlay
              if (!controller.value.isPlaying)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        iconSize: 50,
                        icon: const Icon(Icons.play_arrow, color: Colors.white),
                        onPressed: () {
                          context.read<VideoBloc>().add(const PlayVideo());
                        },
                      ),
                      // Show "Next Video" text if at pause point
                      if (video.pauseAt.inSeconds > 0 &&
                          controller.value.position >= video.pauseAt)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Click to play next video',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              // Progress overlay
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Progress Bar with pause point indicator
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Main progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: LinearProgressIndicator(
                              value: controller.value.duration.inMilliseconds >
                                      0
                                  ? controller.value.position.inMilliseconds /
                                      controller.value.duration.inMilliseconds
                                  : 0.0,
                              backgroundColor:
                                  Colors.grey[300]?.withOpacity(0.5),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                              minHeight: 10,
                            ),
                          ),
                          // Pause point indicator
                          if (video.pauseAt.inSeconds > 0 &&
                              controller.value.duration.inMilliseconds > 0)
                            Positioned(
                              left: (video.pauseAt.inMilliseconds /
                                      controller
                                          .value.duration.inMilliseconds) *
                                  MediaQuery.of(context).size.width *
                                  0.95,
                              child: Container(
                                width: 4,
                                height: 20,
                                decoration: BoxDecoration(
                                  color:
                                      controller.value.position >= video.pauseAt
                                          ? Colors.red
                                          : Colors.yellow,
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      blurRadius: 2,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Time indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(controller.value.position),
                            style: const TextStyle(
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black,
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                          if (video.pauseAt.inSeconds > 0)
                            Text(
                              controller.value.position >= video.pauseAt
                                  ? 'At pause point'
                                  : 'Pause in: ${_formatDuration(video.pauseAt - controller.value.position)}',
                              style: TextStyle(
                                color:
                                    controller.value.position >= video.pauseAt
                                        ? Colors.red
                                        : Colors.yellow,
                                fontWeight: FontWeight.bold,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black,
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          Text(
                            _formatDuration(controller.value.duration),
                            style: const TextStyle(
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black,
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Video Controls
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.replay_10),
                onPressed: () {
                  controller.seekTo(
                    controller.value.position - const Duration(seconds: 10),
                  );
                },
              ),
              IconButton(
                icon: Icon(
                  controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                ),
                onPressed: () {
                  context.read<VideoBloc>().add(
                        controller.value.isPlaying
                            ? const PauseVideo()
                            : const PlayVideo(),
                      );
                },
              ),
              IconButton(
                icon: const Icon(Icons.forward_10),
                onPressed: () {
                  controller.seekTo(
                    controller.value.position + const Duration(seconds: 10),
                  );
                },
              ),
            ],
          ),
        ),

        // Next video indicator
        if (state.currentVideoIndex < 2)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.skip_next),
                const SizedBox(width: 8),
                Text(
                  'Next: ${context.read<VideoBloc>().videos[state.currentVideoIndex + 1].title}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
