import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:equatable/equatable.dart';
import 'dart:io';
import '../../../core/utils/storage_helper.dart';
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
    on<ResumeVideo>(_onResumeVideo);
    on<SavePlaybackState>(_onSavePlaybackState);
    on<RestorePlaybackState>(_onRestorePlaybackState);
    on<VideoCompleted>(_onVideoCompleted);
    _initializeVideoList();
  }

  void _initializeVideoList() {
    videos = [
      VideoModel(
        title: 'First Video',
        path: 'video1.mp4',
        duration: const Duration(seconds: 30),
        pauseAt: const Duration(seconds: 15),
        shouldAutoResume: true,
        resumeAfterVideoIndex: 1,
      ),
      VideoModel(
        title: 'Second Video',
        path: 'video2.mp4',
        duration: const Duration(seconds: 30),
        pauseAt: const Duration(seconds: 20),
        shouldAutoResume: true,
        resumeAfterVideoIndex: 2,
      ),
      VideoModel(
        title: 'Third Video',
        path: 'video3.mp4',
        duration: const Duration(seconds: 30),
        pauseAt: const Duration(seconds: 0),
        shouldAutoResume: false,
      ),
    ];
  }

  Future<void> _onInitializeVideo(
    InitializeVideo event,
    Emitter<VideoState> emit,
  ) async {
    try {
      emit(state.copyWith(status: VideoStatus.loading));

      // Check if videos exist in local storage
      for (final video in videos) {
        if (!await StorageHelper.checkVideoExists(video.path)) {
          emit(state.copyWith(
            status: VideoStatus.error,
            error:
                'Video file not found: ${video.path}. Please ensure all videos are copied to local storage.',
          ));
          return;
        }
      }

      await _restoreLastState();

      if (state.currentVideo != null) {
        final videoFile =
            await StorageHelper.getLocalVideoFile(state.currentVideo!.path);
        await _initializeVideoController(videoFile.path);
        emit(state.copyWith(status: VideoStatus.playing));
        controller!.play();
      } else {
        // Start with the first video if no saved state
        final firstVideo = videos.first;
        final videoFile =
            await StorageHelper.getLocalVideoFile(firstVideo.path);
        await _initializeVideoController(videoFile.path);
        emit(state.copyWith(
          status: VideoStatus.playing,
          currentVideo: firstVideo,
          currentVideoIndex: 0,
        ));
        controller!.play();
      }
    } catch (e) {
      emit(state.copyWith(
        status: VideoStatus.error,
        error: 'Error initializing video: ${e.toString()}',
      ));
    }
  }

  Future<void> _initializeVideoController(String videoPath) async {
    try {
      if (controller != null) {
        await controller!.dispose();
      }
      controller = VideoPlayerController.file(File(videoPath));
      await controller!.initialize();
      controller!.addListener(_videoListener);
    } catch (e) {
      throw Exception('Failed to initialize video: ${e.toString()}');
    }
  }

  Future<void> _onSavePlaybackState(
    SavePlaybackState event,
    Emitter<VideoState> emit,
  ) async {
    if (controller != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('lastVideoIndex', state.currentVideoIndex);
      await prefs.setInt('lastPosition', controller!.value.position.inSeconds);
      await prefs.setString('lastStatus', state.status.toString());
      await prefs.setBool('hasCompletedThirdVideo', hasCompletedThirdVideo);
    }
  }

  Future<void> _onRestorePlaybackState(
    RestorePlaybackState event,
    Emitter<VideoState> emit,
  ) async {
    await _restoreLastState();
  }

  Future<void> _restoreLastState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastVideoIndex = prefs.getInt('lastVideoIndex') ?? 0;
      final lastPosition = prefs.getInt('lastPosition') ?? 0;
      final lastStatusString = prefs.getString('lastStatus');
      hasCompletedThirdVideo = prefs.getBool('hasCompletedThirdVideo') ?? false;

      if (lastVideoIndex < videos.length) {
        final video = videos[lastVideoIndex];
        final videoFile = await StorageHelper.getLocalVideoFile(video.path);

        if (!await videoFile.exists()) {
          throw Exception('Video file not found: ${video.path}');
        }

        emit(state.copyWith(
          currentVideo: video,
          currentVideoIndex: lastVideoIndex,
          status: _parseVideoStatus(lastStatusString),
        ));

        if (controller != null) {
          await controller!.seekTo(Duration(seconds: lastPosition));
          if (state.status == VideoStatus.playing) {
            controller!.play();
          }
        }
      }
    } catch (e) {
      emit(state.copyWith(
        error: 'Error restoring playback state: ${e.toString()}',
        status: VideoStatus.error,
      ));
    }
  }

  Future<void> _switchToVideo(int index) async {
    if (index < 0 || index >= videos.length) return;

    try {
      final nextVideo = videos[index];
      final videoFile = await StorageHelper.getLocalVideoFile(nextVideo.path);

      if (!await videoFile.exists()) {
        throw Exception('Video file not found: ${nextVideo.path}');
      }

      await _initializeVideoController(videoFile.path);
      emit(state.copyWith(
        currentVideo: nextVideo,
        currentVideoIndex: index,
        status: VideoStatus.playing,
        error: '', // Clear any previous errors
      ));
      controller!.play();
    } catch (e) {
      emit(state.copyWith(
        status: VideoStatus.error,
        error: 'Error switching video: ${e.toString()}',
      ));
    }
  }

  void _videoListener() {
    if (controller == null) return;

    final currentVideo = state.currentVideo;
    if (currentVideo == null) return;

    final position = controller!.value.position;

    // Check for pause points
    if (currentVideo.pauseAt.inSeconds > 0 &&
        position >= currentVideo.pauseAt &&
        controller!.value.isPlaying) {
      controller!.pause();
      add(const PauseVideo());
    }

    // Check for video completion
    if (position >=
        controller!.value.duration - const Duration(milliseconds: 100)) {
      add(const VideoCompleted());
    }
  }

  Future<void> _onVideoCompleted(
    VideoCompleted event,
    Emitter<VideoState> emit,
  ) async {
    final currentIndex = state.currentVideoIndex;

    // If third video completes
    if (currentIndex == 2) {
      hasCompletedThirdVideo = true;
      await _switchToVideo(1); // Switch to second video
      await _onSavePlaybackState(
          const SavePlaybackState(), emit); // Save state after completion
    }
    // If second video completes after third video
    else if (currentIndex == 1 && hasCompletedThirdVideo) {
      await _switchToVideo(0); // Switch back to first video
      await _onSavePlaybackState(
          const SavePlaybackState(), emit); // Save state after completion
    }
    // For first video or other cases, move to next video
    else if (currentIndex < videos.length - 1) {
      await _switchToVideo(currentIndex + 1);
      await _onSavePlaybackState(
          const SavePlaybackState(), emit); // Save state after completion
    }
  }

  void _onPlayVideo(PlayVideo event, Emitter<VideoState> emit) {
    if (controller != null) {
      final currentVideo = state.currentVideo;
      if (currentVideo == null) return;

      // If we're at a pause point, move to next video instead of resuming
      if (controller!.value.position >= currentVideo.pauseAt &&
          currentVideo.pauseAt.inSeconds > 0) {
        // Move to next video if available
        if (state.currentVideoIndex < videos.length - 1) {
          _switchToVideo(state.currentVideoIndex + 1);
          return;
        }
      }

      controller!.play();
      emit(state.copyWith(status: VideoStatus.playing));
    }
  }

  void _onPauseVideo(PauseVideo event, Emitter<VideoState> emit) {
    if (controller != null) {
      controller!.pause();
      emit(state.copyWith(status: VideoStatus.paused));
    }
  }

  void _onResumeVideo(ResumeVideo event, Emitter<VideoState> emit) {
    if (controller != null) {
      final currentVideo = state.currentVideo;
      if (currentVideo == null) return;

      // If we're at a pause point, move to next video
      if (controller!.value.position >= currentVideo.pauseAt &&
          currentVideo.pauseAt.inSeconds > 0) {
        // Move to next video if available
        if (state.currentVideoIndex < videos.length - 1) {
          _switchToVideo(state.currentVideoIndex + 1);
          return;
        }
      }

      controller!.play();
      emit(state.copyWith(status: VideoStatus.playing));
    }
  }

  VideoStatus _parseVideoStatus(String? status) {
    switch (status) {
      case 'VideoStatus.playing':
        return VideoStatus.playing;
      case 'VideoStatus.paused':
        return VideoStatus.paused;
      default:
        return VideoStatus.initial;
    }
  }

  @override
  Future<void> close() {
    controller?.dispose();
    return super.close();
  }
}
