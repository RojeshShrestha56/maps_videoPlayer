import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import 'package:equatable/equatable.dart';
import '../models/video_model.dart';

part 'video_event.dart';
part 'video_state.dart';

class VideoBloc extends Bloc<VideoEvent, VideoState> {
  VideoPlayerController? controller;
  late List<VideoModel> videos;
  bool hasCompletedThirdVideo = false;

  VideoBloc() : super(const VideoState()) {
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
    _initializeVideoList();
  }

  void _initializeVideoList() {
    videos = [
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
        pauseAt: Duration(seconds: 0),
      ),
    ];
  }

  Future<void> _onInitializeVideo(
    InitializeVideo event,
    Emitter<VideoState> emit,
  ) async {
    try {
      emit(state.copyWith(status: VideoStatus.loading));
      final firstVideo = videos.first;
      await _initializeVideoController(firstVideo.path);
      emit(state.copyWith(
        status: VideoStatus.playing,
        currentVideo: firstVideo,
        currentVideoIndex: 0,
        totalDuration: controller!.value.duration,
      ));
      controller!.play();
    } catch (e) {
      add(VideoError('Error initializing video: ${e.toString()}'));
    }
  }

  Future<void> _initializeVideoController(String videoPath) async {
    try {
      await controller?.dispose();
      controller = VideoPlayerController.asset(videoPath);
      await controller!.initialize();
      controller!.addListener(_videoListener);
    } catch (e) {
      throw Exception('Failed to initialize video: ${e.toString()}');
    }
  }

  void _videoListener() {
    if (controller == null || !controller!.value.isInitialized) return;

    add(UpdateVideoPosition(
      position: controller!.value.position,
      duration: controller!.value.duration,
    ));

    if (state.atPausePoint && controller!.value.isPlaying) {
      add(const PauseVideo());
    }

    if (controller!.value.position >=
        controller!.value.duration - const Duration(milliseconds: 100)) {
      add(const VideoCompleted());
    }
  }

  void _onPlayVideo(PlayVideo event, Emitter<VideoState> emit) {
    if (controller == null || !controller!.value.isInitialized) return;

    if (state.atPausePoint) {
      if (state.currentVideoIndex < videos.length - 1) {
        add(SwitchToVideo(state.currentVideoIndex + 1));
        return;
      }
    }

    controller!.play();
    emit(state.copyWith(status: VideoStatus.playing));
  }

  void _onPauseVideo(PauseVideo event, Emitter<VideoState> emit) {
    if (controller == null || !controller!.value.isInitialized) return;
    controller!.pause();
    emit(state.copyWith(status: VideoStatus.paused));
  }

  void _onSeekVideo(SeekVideo event, Emitter<VideoState> emit) {
    if (controller == null || !controller!.value.isInitialized) return;
    controller!.seekTo(event.position);
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

    if (currentIndex == 2) {
      hasCompletedThirdVideo = true;
      add(const SwitchToVideo(1));
    } else if (currentIndex == 1 && hasCompletedThirdVideo) {
      add(const SwitchToVideo(0));
    } else if (currentIndex < videos.length - 1) {
      add(SwitchToVideo(currentIndex + 1));
    }
  }

  Future<void> _onSwitchToVideo(
    SwitchToVideo event,
    Emitter<VideoState> emit,
  ) async {
    if (event.index < 0 || event.index >= videos.length) return;

    try {
      final nextVideo = videos[event.index];
      await _initializeVideoController(nextVideo.path);
      emit(state.copyWith(
        currentVideo: nextVideo,
        currentVideoIndex: event.index,
        status: VideoStatus.playing,
        error: '',
        currentPosition: Duration.zero,
        totalDuration: controller!.value.duration,
      ));
      controller!.play();
    } catch (e) {
      add(VideoError('Error switching video: ${e.toString()}'));
    }
  }

  void _onSavePlaybackState(SavePlaybackState event, Emitter<VideoState> emit) {
    // Implement save playback state logic if needed
  }

  void _onRestorePlaybackState(
      RestorePlaybackState event, Emitter<VideoState> emit) {
    // Implement restore playback state logic if needed
  }

  void _onVideoError(VideoError event, Emitter<VideoState> emit) {
    emit(state.copyWith(
      status: VideoStatus.error,
      error: event.message,
    ));
  }

  @override
  Future<void> close() {
    controller?.dispose();
    return super.close();
  }
}
