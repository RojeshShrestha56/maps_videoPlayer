class VideoModel {
  final String title;
  final String path;
  final Duration duration;
  final Duration pauseAt;

  const VideoModel({
    required this.title,
    required this.path,
    required this.duration,
    required this.pauseAt,
  });
}
