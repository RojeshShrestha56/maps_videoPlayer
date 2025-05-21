import 'package:dio/dio.dart';
import '../../modules/map/models/get_direction_model.dart';
import '../providers/network/api_endpoint.dart';

class ApiProvider {
  final Dio _dio;
  final String _apiKey = 'bpk.Lrp6rRIjOpVullIjTRPevEl-2uZPMgMQhnWnEHSxrGUG';

  ApiProvider() : _dio = Dio();

  Future<List<DirectionData>> getDirections({
    required List<List<double>> points,
  }) async {
    try {
      final pointsParam =
          points.map((point) => '${point[0]},${point[1]}').toList();

      final response = await _dio.get(
        '${ApiEndpoint.baseUrl}directions',
        queryParameters: {
          'key': _apiKey,
          'points[]': pointsParam,
          'mode': 'car',
        },
      );

      if (response.statusCode == 200) {
        final GetDirectionModel directionModel =
            GetDirectionModel.fromJson(response.data);
        return directionModel.data;
      } else {
        throw Exception('Failed to load directions: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting directions: $e');
    }
  }
}
