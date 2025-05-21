class GetDirectionModel {
  GetDirectionModel({
    required this.timestamp,
    required this.status,
    required this.message,
    required this.data,
  });

  final String? timestamp;
  final int? status;
  final String? message;
  final List<DirectionData> data;

  GetDirectionModel copyWith({
    String? timestamp,
    int? status,
    String? message,
    List<DirectionData>? data,
  }) {
    return GetDirectionModel(
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      message: message ?? this.message,
      data: data ?? this.data,
    );
  }

  factory GetDirectionModel.fromJson(Map<String, dynamic> json) {
    return GetDirectionModel(
      timestamp: json["timestamp"],
      status: json["status"],
      message: json["message"],
      data: json["data"] == null
          ? []
          : List<DirectionData>.from(
              json["data"]!.map((x) => DirectionData.fromJson(x)),
            ),
    );
  }

  Map<String, dynamic> toJson() => {
        "timestamp": timestamp,
        "status": status,
        "message": message,
        "data": data.map((x) => x.toJson()).toList(),
      };

  @override
  String toString() {
    return "$timestamp, $status, $message, $data, ";
  }
}

class DirectionData {
  DirectionData({
    required this.encodedPolyline,
    required this.distanceInMeters,
    required this.timeInMs,
    required this.instructionList,
  });

  final String encodedPolyline;
  final double? distanceInMeters;
  final int? timeInMs;
  final dynamic instructionList;

  DirectionData copyWith({
    String? encodedPolyline,
    double? distanceInMeters,
    int? timeInMs,
    dynamic? instructionList,
  }) {
    return DirectionData(
      encodedPolyline: encodedPolyline ?? this.encodedPolyline,
      distanceInMeters: distanceInMeters ?? this.distanceInMeters,
      timeInMs: timeInMs ?? this.timeInMs,
      instructionList: instructionList ?? this.instructionList,
    );
  }

  factory DirectionData.fromJson(Map<String, dynamic> json) {
    return DirectionData(
      encodedPolyline: json["encodedPolyline"] ?? '',
      distanceInMeters: json["distanceInMeters"],
      timeInMs: json["timeInMs"],
      instructionList: json["instructionList"],
    );
  }

  Map<String, dynamic> toJson() => {
        "encodedPolyline": encodedPolyline,
        "distanceInMeters": distanceInMeters,
        "timeInMs": timeInMs,
        "instructionList": instructionList,
      };

  @override
  String toString() {
    return "$encodedPolyline, $distanceInMeters, $timeInMs, $instructionList, ";
  }
}
