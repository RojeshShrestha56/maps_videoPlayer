import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../core/utils/storage_helper.dart';

class VideoSetupWidget extends StatefulWidget {
  const VideoSetupWidget({super.key});

  @override
  State<VideoSetupWidget> createState() => _VideoSetupWidgetState();
}

class _VideoSetupWidgetState extends State<VideoSetupWidget> {
  final List<String> requiredVideos = [
    'video1.mp4',
    'video2.mp4',
    'video3.mp4'
  ];
  final Map<String, bool> videoStatus = {};
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkVideos();
  }

  Future<void> _checkVideos() async {
    setState(() {
      isLoading = true;
    });

    for (final video in requiredVideos) {
      videoStatus[video] = await StorageHelper.checkVideoExists(video);
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _pickAndCopyVideo(String targetFilename) async {
    try {
      setState(() {
        isLoading = true;
      });

      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          await StorageHelper.copyVideoToLocal(file.path!, targetFilename);
          await _checkVideos();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error copying video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final allVideosReady = videoStatus.values.every((status) => status);
    if (allVideosReady) {
      return const SizedBox
          .shrink(); // Hide the widget when all videos are ready
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Video Setup Required',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Please select the following videos from your device:',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ...requiredVideos.map((video) {
              final isReady = videoStatus[video] ?? false;
              return ListTile(
                leading: Icon(
                  isReady ? Icons.check_circle : Icons.error_outline,
                  color: isReady ? Colors.green : Colors.red,
                ),
                title: Text(video),
                subtitle: Text(isReady ? 'Ready' : 'Not found'),
                trailing: isReady
                    ? null
                    : ElevatedButton(
                        onPressed: () => _pickAndCopyVideo(video),
                        child: const Text('Select Video'),
                      ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
