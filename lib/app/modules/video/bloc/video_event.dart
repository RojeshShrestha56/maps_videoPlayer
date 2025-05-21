part of 'video_bloc.dart';

abstract class VideoEvent extends Equatable {
  const VideoEvent();

  @override
  List<Object?> get props => [];
}

class InitializeVideo extends VideoEvent {
  const InitializeVideo();
}

class PlayVideo extends VideoEvent {
  const PlayVideo();

  @override
  List<Object> get props => [];
}

class PauseVideo extends VideoEvent {
  const PauseVideo();

  @override
  List<Object> get props => [];
}

class SeekVideo extends VideoEvent {
  final Duration position;

  const SeekVideo(this.position);

  @override
  List<Object> get props => [position];
}

class UpdateVideoPosition extends VideoEvent {
  final Duration position;
  final Duration duration;

  const UpdateVideoPosition({
    required this.position,
    required this.duration,
  });

  @override
  List<Object> get props => [position, duration];
}

class VideoCompleted extends VideoEvent {
  const VideoCompleted();

  @override
  List<Object> get props => [];
}

class SwitchToVideo extends VideoEvent {
  final int index;

  const SwitchToVideo(this.index);

  @override
  List<Object> get props => [index];
}

class SavePlaybackState extends VideoEvent {
  const SavePlaybackState();

  @override
  List<Object> get props => [];
}

class RestorePlaybackState extends VideoEvent {
  const RestorePlaybackState();

  @override
  List<Object> get props => [];
}

class VideoError extends VideoEvent {
  final String message;

  const VideoError(this.message);

  @override
  List<Object> get props => [message];
}
