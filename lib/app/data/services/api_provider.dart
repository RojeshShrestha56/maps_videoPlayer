import 'package:dio/dio.dart';
import '../../modules/map/models/get_direction_model.dart';
import '../providers/network/api_endpoint.dart';

class ApiProvider {
  final Dio _dio;

  ApiProvider() : _dio = Dio() {
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }

  Future<List<DirectionData>> getDirections({
    required List<List<double>> points,
  }) async {
    try {
      final pointsParam =
          points.map((point) => '${point[0]},${point[1]}').toList();
      const String url = '${ApiEndpoint.baseUrl}directions';

      final queryParams = {
        'key': ApiEndpoint.apiKey,
        'points[]': pointsParam,
        'mode': 'car',
      };
      final response = await _dio.get(
        url,
        queryParameters: queryParams,
      );
      if (response.statusCode == 200) {
        if (response.data == null) {
          throw Exception('API response data is null');
        }

        final GetDirectionModel directionModel =
            GetDirectionModel.fromJson(response.data);
        if (directionModel.data.isEmpty) {
          throw Exception('No routes found in API response');
        }

        return directionModel.data;
      } else {
        throw Exception('Failed to load directions: ${response.statusCode}');
      }
    } on DioException catch (e) {
      throw Exception('Network error getting directions: ${e.message}');
    } catch (e) {
      throw Exception('Error getting directions: $e');
    }
  }
}
