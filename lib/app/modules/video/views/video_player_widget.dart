import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import '../bloc/video_bloc.dart';

class VideoPlayerWidget extends StatelessWidget {
  const VideoPlayerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VideoBloc>().add(const InitializeVideo());
    });

    return BlocConsumer<VideoBloc, VideoState>(
      listener: (context, state) {
        if (state.hasError) {
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
            Expanded(
              child: _buildVideoContent(context, state),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVideoContent(BuildContext context, VideoState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.hasError) {
      return _buildErrorView(context, state);
    }

    if (!state.hasVideo ||
        state.controller == null ||
        !state.controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        _buildVideoHeader(context, state),
        Expanded(
          child: _buildVideoPlayer(context, state, state.controller!),
        ),
        _buildVideoControls(context, state, state.controller!),
        if (state.currentVideoIndex < 2) _buildNextVideoInfo(context, state),
      ],
    );
  }

  Widget _buildErrorView(BuildContext context, VideoState state) {
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
            onPressed: () =>
                context.read<VideoBloc>().add(const InitializeVideo()),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoHeader(BuildContext context, VideoState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              state.currentVideo!.title,
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
    );
  }

  Widget _buildVideoPlayer(BuildContext context, VideoState state,
      VideoPlayerController controller) {
    if (!controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return AspectRatio(
      aspectRatio: controller.value.aspectRatio,
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(controller),
          if (!controller.value.isPlaying)
            _buildPlayPauseOverlay(context, state),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildProgressOverlay(context, state, controller),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayPauseOverlay(BuildContext context, VideoState state) {
    return Container(
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
            onPressed: () => context.read<VideoBloc>().add(const PlayVideo()),
          ),
          if (state.atPausePoint)
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
    );
  }

  Widget _buildProgressOverlay(BuildContext context, VideoState state,
      VideoPlayerController controller) {
    return Container(
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
          Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: state.progress,
                  backgroundColor: Colors.grey[300]?.withOpacity(0.5),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 10,
                ),
              ),
              if (state.currentVideo!.pauseAt.inSeconds > 0)
                Positioned(
                  left: (state.currentVideo!.pauseAt.inMilliseconds /
                          state.totalDuration.inMilliseconds) *
                      MediaQuery.of(context).size.width *
                      0.95,
                  child: Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: state.atPausePoint ? Colors.red : Colors.yellow,
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
          _buildTimeDisplay(context, state),
        ],
      ),
    );
  }

  Widget _buildTimeDisplay(BuildContext context, VideoState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _formatDuration(state.currentPosition),
          style: _timeTextStyle,
        ),
        if (state.currentVideo!.pauseAt.inSeconds > 0)
          Text(
            state.atPausePoint
                ? 'At pause point'
                : 'Pause in: ${_formatDuration(state.timeUntilPause)}',
            style: TextStyle(
              color: state.atPausePoint ? Colors.red : Colors.yellow,
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
          _formatDuration(state.totalDuration),
          style: _timeTextStyle,
        ),
      ],
    );
  }

  Widget _buildVideoControls(BuildContext context, VideoState state,
      VideoPlayerController controller) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.replay_10),
            onPressed: () {
              context.read<VideoBloc>().add(
                    SeekVideo(
                        state.currentPosition - const Duration(seconds: 10)),
                  );
            },
          ),
          IconButton(
            icon: Icon(state.isPlaying ? Icons.pause : Icons.play_arrow),
            onPressed: () {
              context.read<VideoBloc>().add(
                    state.isPlaying ? const PauseVideo() : const PlayVideo(),
                  );
            },
          ),
          IconButton(
            icon: const Icon(Icons.forward_10),
            onPressed: () {
              context.read<VideoBloc>().add(
                    SeekVideo(
                        state.currentPosition + const Duration(seconds: 10)),
                  );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNextVideoInfo(BuildContext context, VideoState state) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          const Icon(Icons.skip_next),
          const SizedBox(width: 8),
          Text(
            'Next: ${state.videos[state.currentVideoIndex + 1].title}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  static const _timeTextStyle = TextStyle(
    color: Colors.white,
    shadows: [
      Shadow(
        color: Colors.black,
        blurRadius: 2,
      ),
    ],
  );
}
