part of 'video_bloc.dart';

enum VideoStatus { initial, loading, playing, paused, completed, error }

class VideoState extends Equatable {
  final VideoStatus status;
  final VideoModel? currentVideo;
  final int currentVideoIndex;
  final String error;

  const VideoState({
    this.status = VideoStatus.initial,
    this.currentVideo,
    this.currentVideoIndex = 0,
    this.error = '',
  });

  VideoState copyWith({
    VideoStatus? status,
    VideoModel? currentVideo,
    int? currentVideoIndex,
    String? error,
  }) {
    return VideoState(
      status: status ?? this.status,
      currentVideo: currentVideo ?? this.currentVideo,
      currentVideoIndex: currentVideoIndex ?? this.currentVideoIndex,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, currentVideo, currentVideoIndex, error];
}
