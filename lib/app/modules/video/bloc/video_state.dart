part of 'video_bloc.dart';

enum VideoStatus { initial, loading, playing, paused, completed, error }

class VideoState extends Equatable {
  final VideoStatus status;
  final VideoModel? currentVideo;
  final int currentVideoIndex;
  final String error;
  final Duration currentPosition;
  final Duration totalDuration;
  final bool isBuffering;
  final VideoPlayerController? controller;
  final List<VideoModel> videos;
  final bool hasCompletedThirdVideo;
  static const String videoIndexKey = 'video_index';
  static const String videoPositionKey = 'video_position';
  static const String hasCompletedThirdVideoKey = 'completed_third_video';

  const VideoState({
    this.status = VideoStatus.initial,
    this.currentVideo,
    this.currentVideoIndex = 0,
    this.error = '',
    this.currentPosition = Duration.zero,
    this.totalDuration = Duration.zero,
    this.isBuffering = false,
    this.controller,
    this.videos = const [],
    this.hasCompletedThirdVideo = false,
  });

  VideoState copyWith({
    VideoStatus? status,
    VideoModel? currentVideo,
    int? currentVideoIndex,
    String? error,
    Duration? currentPosition,
    Duration? totalDuration,
    bool? isBuffering,
    VideoPlayerController? controller,
    List<VideoModel>? videos,
    bool? hasCompletedThirdVideo,
  }) {
    return VideoState(
      status: status ?? this.status,
      currentVideo: currentVideo ?? this.currentVideo,
      currentVideoIndex: currentVideoIndex ?? this.currentVideoIndex,
      error: error ?? this.error,
      currentPosition: currentPosition ?? this.currentPosition,
      totalDuration: totalDuration ?? this.totalDuration,
      isBuffering: isBuffering ?? this.isBuffering,
      controller: controller ?? this.controller,
      videos: videos ?? this.videos,
      hasCompletedThirdVideo:
          hasCompletedThirdVideo ?? this.hasCompletedThirdVideo,
    );
  }

  bool get isPlaying => status == VideoStatus.playing;
  bool get isPaused => status == VideoStatus.paused;
  bool get isLoading => status == VideoStatus.loading;
  bool get hasError => status == VideoStatus.error;
  bool get isInitial => status == VideoStatus.initial;
  bool get isCompleted => status == VideoStatus.completed;

  bool get hasVideo => currentVideo != null;
  bool get atPausePoint =>
      hasVideo &&
      currentVideo!.pauseAt.inSeconds > 0 &&
      currentPosition >= currentVideo!.pauseAt;

  double get progress => totalDuration.inMilliseconds > 0
      ? currentPosition.inMilliseconds / totalDuration.inMilliseconds
      : 0.0;

  Duration get timeUntilPause => hasVideo && currentVideo!.pauseAt.inSeconds > 0
      ? currentVideo!.pauseAt - currentPosition
      : Duration.zero;

  @override
  List<Object?> get props => [
        status,
        currentVideo,
        currentVideoIndex,
        error,
        currentPosition,
        totalDuration,
        isBuffering,
        controller,
        videos,
        hasCompletedThirdVideo,
      ];
}
