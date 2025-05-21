class VideoModel {
  final String title;
  final String path;
  final Duration duration;
  final Duration pauseAt;
  final bool
      shouldAutoResume; // Indicates if this video should auto-resume after completion of another
  final int
      resumeAfterVideoIndex; // Index of video after which this should resume, -1 if not applicable

  const VideoModel({
    required this.title,
    required this.path,
    required this.duration,
    required this.pauseAt,
    this.shouldAutoResume = false,
    this.resumeAfterVideoIndex = -1,
  });
}
