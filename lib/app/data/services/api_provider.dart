import 'package:dio/dio.dart';
import '../../modules/map/models/get_direction_model.dart';
import '../providers/network/api_endpoint.dart';

class ApiProvider {
  final Dio _dio;

  ApiProvider() : _dio = Dio() {
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => print('Dio Log: $obj'),
    ));
  }

  Future<List<DirectionData>> getDirections({
    required List<List<double>> points,
  }) async {
    try {
      final pointsParam =
          points.map((point) => '${point[0]},${point[1]}').toList();

      print('Making API request to get directions with points: $pointsParam');
      final String url = '${ApiEndpoint.baseUrl}directions';
      print('Request URL: $url');

      final queryParams = {
        'key': ApiEndpoint.apiKey,
        'points[]': pointsParam,
        'mode': 'car',
      };
      print('Request query parameters: $queryParams');

      final response = await _dio.get(
        url,
        queryParameters: queryParams,
      );

      print('API Response status: ${response.statusCode}');
      print('API Response headers: ${response.headers}');
      print('API Response data: ${response.data}');

      if (response.statusCode == 200) {
        if (response.data == null) {
          throw Exception('API response data is null');
        }

        final GetDirectionModel directionModel =
            GetDirectionModel.fromJson(response.data);
        print('Parsed direction model: ${directionModel.data.length} routes');

        if (directionModel.data.isEmpty) {
          throw Exception('No routes found in API response');
        }

        return directionModel.data;
      } else {
        throw Exception('Failed to load directions: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('Dio Error: ${e.type}');
      print('Error Message: ${e.message}');
      print('Error Response: ${e.response?.data}');
      throw Exception('Network error getting directions: ${e.message}');
    } catch (e) {
      print('API Error: $e');
      throw Exception('Error getting directions: $e');
    }
  }
}
