import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/widgets.dart';
import '../models/video_model.dart';
import '../../../data/services/api_provider.dart';

part 'video_event.dart';
part 'video_state.dart';

class VideoBloc extends Bloc<VideoEvent, VideoState>
    with WidgetsBindingObserver {
  final ApiProvider _apiProvider;

  VideoBloc({required ApiProvider apiProvider})
      : _apiProvider = apiProvider,
        super(VideoState(videos: [
          const VideoModel(
            title: 'First Video',
            path: 'assets/videos/video1.mp4',
            duration: Duration(seconds: 30),
            pauseAt: Duration(seconds: 15),
          ),
          const VideoModel(
            title: 'Second Video',
            path: 'assets/videos/video2.mp4',
            duration: Duration(seconds: 30),
            pauseAt: Duration(seconds: 20),
          ),
          const VideoModel(
            title: 'Third Video',
            path: 'assets/videos/video3.mp4',
            duration: Duration(seconds: 30),
            pauseAt: Duration.zero,
          ),
        ])) {
    on<InitializeVideo>(_onInitializeVideo);
    on<PlayVideo>(_onPlayVideo);
    on<PauseVideo>(_onPauseVideo);
    on<SeekVideo>(_onSeekVideo);
    on<UpdateVideoPosition>(_onUpdateVideoPosition);
    on<VideoCompleted>(_onVideoCompleted);
    on<SwitchToVideo>(_onSwitchToVideo);
    on<SavePlaybackState>(_onSavePlaybackState);
    on<RestorePlaybackState>(_onRestorePlaybackState);
    on<VideoError>(_onVideoError);

    WidgetsBinding.instance.addObserver(this);
  }

  String formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      add(const SavePlaybackState());
    } else if (state == AppLifecycleState.resumed) {
      add(const RestorePlaybackState());
    }
  }

  Future<void> _initializeVideoController(
      String videoPath, Emitter<VideoState> emit) async {
    try {
      if (state.controller != null) {
        await state.controller!.dispose();
        emit(state.copyWith(controller: null));
      }

      final controller = VideoPlayerController.asset(videoPath);
      await controller.initialize();

      final size = controller.value.size;
      final width = size.width;
      final height = size.height;

      if (width > 1920 || height > 1080) {
        throw Exception(
            'Video resolution ${width.toInt()}x${height.toInt()} exceeds device capabilities. Please use videos with maximum 1080p resolution.');
      }

      controller.addListener(() => _videoListener(emit));
      emit(state.copyWith(controller: controller));
    } catch (e) {
      throw Exception('Failed to initialize video: ${e.toString()}');
    }
  }

  void _videoListener(Emitter<VideoState> emit) {
    if (state.controller == null || !state.controller!.value.isInitialized)
      return;

    add(UpdateVideoPosition(
      position: state.controller!.value.position,
      duration: state.controller!.value.duration,
    ));

    if (!state.hasCompletedThirdVideo &&
        state.currentVideoIndex < 2 &&
        state.atPausePoint &&
        state.controller!.value.isPlaying) {
      state.controller!.pause();
      add(SwitchToVideo(state.currentVideoIndex + 1));
      return;
    }

    if (state.controller!.value.position >=
        state.controller!.value.duration - const Duration(milliseconds: 100)) {
      add(const VideoCompleted());
    }
  }

  void _onPlayVideo(PlayVideo event, Emitter<VideoState> emit) {
    if (state.controller == null || !state.controller!.value.isInitialized)
      return;

    if (state.atPausePoint) {
      return;
    }

    state.controller!.play();
    emit(state.copyWith(status: VideoStatus.playing));
  }

  void _onPauseVideo(PauseVideo event, Emitter<VideoState> emit) {
    if (state.controller == null || !state.controller!.value.isInitialized)
      return;
    state.controller!.pause();
    emit(state.copyWith(status: VideoStatus.paused));
  }

  void _onSeekVideo(SeekVideo event, Emitter<VideoState> emit) {
    if (state.controller == null || !state.controller!.value.isInitialized)
      return;
    state.controller!.seekTo(event.position);
  }

  void _onUpdateVideoPosition(
    UpdateVideoPosition event,
    Emitter<VideoState> emit,
  ) {
    emit(state.copyWith(
      currentPosition: event.position,
      totalDuration: event.duration,
    ));
  }

  Future<void> _onVideoCompleted(
    VideoCompleted event,
    Emitter<VideoState> emit,
  ) async {
    final currentIndex = state.currentVideoIndex;

    if (!state.hasCompletedThirdVideo) {
      if (currentIndex < 2) {
        add(SwitchToVideo(currentIndex + 1));
      } else if (currentIndex == 2) {
        emit(state.copyWith(hasCompletedThirdVideo: true));
        add(const SwitchToVideo(1));
      }
    } else {
      if (currentIndex == 1) {
        add(const SwitchToVideo(0));
      } else if (currentIndex == 0) {
        add(const SwitchToVideo(1));
      }
    }
  }

  Future<void> _onSwitchToVideo(
    SwitchToVideo event,
    Emitter<VideoState> emit,
  ) async {
    if (event.index < 0 || event.index >= state.videos.length) return;

    try {
      final nextVideo = state.videos[event.index];

      emit(state.copyWith(
        status: VideoStatus.loading,
        currentVideo: nextVideo,
        currentVideoIndex: event.index,
        error: '',
        currentPosition: Duration.zero,
      ));

      await _initializeVideoController(nextVideo.path, emit);

      if (state.hasCompletedThirdVideo && event.index == 0) {
        await state.controller!.seekTo(nextVideo.pauseAt);
      }

      emit(state.copyWith(
        status: VideoStatus.playing,
        totalDuration: state.controller!.value.duration,
      ));

      state.controller!.play();
    } catch (e) {
      add(VideoError('Error switching video: ${e.toString()}'));
    }
  }

  Future<void> _onSavePlaybackState(
    SavePlaybackState event,
    Emitter<VideoState> emit,
  ) async {
    try {
      if (state.controller == null || !state.controller!.value.isInitialized)
        return;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(VideoState.videoIndexKey, state.currentVideoIndex);
      await prefs.setInt(
        VideoState.videoPositionKey,
        state.controller!.value.position.inMilliseconds,
      );
      await prefs.setBool(
          VideoState.hasCompletedThirdVideoKey, state.hasCompletedThirdVideo);
    } catch (e) {
      add(VideoError('Error saving playback state: ${e.toString()}'));
    }
  }

  Future<void> _onRestorePlaybackState(
    RestorePlaybackState event,
    Emitter<VideoState> emit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final hasCompletedThirdVideo =
          prefs.getBool(VideoState.hasCompletedThirdVideoKey) ?? false;

      final savedIndex = prefs.getInt(VideoState.videoIndexKey);
      if (savedIndex == null || savedIndex >= state.videos.length) {
        add(const InitializeVideo());
        return;
      }

      final savedPosition = prefs.getInt(VideoState.videoPositionKey);
      if (savedPosition == null) {
        add(const InitializeVideo());
        return;
      }

      final savedVideo = state.videos[savedIndex];
      await _initializeVideoController(savedVideo.path, emit);

      emit(state.copyWith(
        status: VideoStatus.paused,
        currentVideo: savedVideo,
        currentVideoIndex: savedIndex,
        totalDuration: state.controller!.value.duration,
        hasCompletedThirdVideo: hasCompletedThirdVideo,
      ));

      await state.controller!.seekTo(Duration(milliseconds: savedPosition));
    } catch (e) {
      add(VideoError('Error restoring playback state: ${e.toString()}'));
      add(const InitializeVideo());
    }
  }

  void _onVideoError(VideoError event, Emitter<VideoState> emit) {
    emit(state.copyWith(
      status: VideoStatus.error,
      error: event.message,
    ));

    if (state.currentVideoIndex < state.videos.length - 1) {
      add(SwitchToVideo(state.currentVideoIndex + 1));
    }
  }

  Future<void> _onInitializeVideo(
    InitializeVideo event,
    Emitter<VideoState> emit,
  ) async {
    try {
      emit(state.copyWith(status: VideoStatus.loading));
      final firstVideo = state.videos.first;
      await _initializeVideoController(firstVideo.path, emit);
      emit(state.copyWith(
        status: VideoStatus.playing,
        currentVideo: firstVideo,
        currentVideoIndex: 0,
        totalDuration: state.controller!.value.duration,
      ));
      state.controller!.play();
    } catch (e) {
      add(VideoError('Error initializing video: ${e.toString()}'));
    }
  }

  @override
  Future<void> close() async {
    WidgetsBinding.instance.removeObserver(this);
    if (state.controller != null) {
      await state.controller!.dispose();
    }
    return super.close();
  }
}
