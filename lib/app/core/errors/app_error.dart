enum ErrorType {
  network,
  video,
  map,
  location,
  unknown,
}

class AppError implements Exception {
  final String message;
  final ErrorType type;
  final dynamic originalError;

  AppError({
    required this.message,
    required this.type,
    this.originalError,
  });

  @override
  String toString() => message;

  static AppError handleError(dynamic error) {
    if (error is AppError) return error;

    // Network errors
    if (error.toString().contains('SocketException') ||
        error.toString().contains('HttpException')) {
      return AppError(
        message:
            'Network connection error. Please check your internet connection.',
        type: ErrorType.network,
        originalError: error,
      );
    }

    // Video errors
    if (error.toString().contains('VideoError') ||
        error.toString().contains('VideoPlayerException')) {
      return AppError(
        message: 'Error playing video. Please try again.',
        type: ErrorType.video,
        originalError: error,
      );
    }

    // Map errors
    if (error.toString().contains('MapLibreError')) {
      return AppError(
        message: 'Error loading map. Please try again.',
        type: ErrorType.map,
        originalError: error,
      );
    }

    // Location errors
    if (error.toString().contains('LocationError') ||
        error.toString().contains('PermissionDenied')) {
      return AppError(
        message: 'Location access denied. Please enable location services.',
        type: ErrorType.location,
        originalError: error,
      );
    }

    // Default error
    return AppError(
      message: 'An unexpected error occurred. Please try again.',
      type: ErrorType.unknown,
      originalError: error,
    );
  }
}
