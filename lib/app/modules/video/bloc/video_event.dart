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
}

class PauseVideo extends VideoEvent {
  const PauseVideo();
}

class ResumeVideo extends VideoEvent {
  const ResumeVideo();
}

class VideoCompleted extends VideoEvent {
  const VideoCompleted();

  @override
  List<Object?> get props => [];
}

class SavePlaybackState extends VideoEvent {
  const SavePlaybackState();
}

class RestorePlaybackState extends VideoEvent {
  const RestorePlaybackState();
}
