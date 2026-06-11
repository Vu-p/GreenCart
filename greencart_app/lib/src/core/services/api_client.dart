import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/api_config.dart';
import 'token_storage.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.watch(tokenStorageProvider));
});

class ApiClient {
  ApiClient(this._tokenStorage)
    : _dio = Dio(
        BaseOptions(
          baseUrl: ApiConfig.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {'Content-Type': 'application/json'},
        ),
      );

  final TokenStorage _tokenStorage;
  final Dio _dio;

  Future<Response<dynamic>> get(
    String path, {
    bool authorized = false,
    Map<String, dynamic>? queryParameters,
  }) async {
    return _dio.get(
      path,
      queryParameters: queryParameters,
      options: await _options(authorized),
    );
  }

  Future<Response<dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
    bool authorized = false,
  }) async {
    return _dio.post(path, data: data, options: await _options(authorized));
  }

  Future<Response<dynamic>> put(
    String path, {
    Map<String, dynamic>? data,
    bool authorized = false,
  }) async {
    return _dio.put(path, data: data, options: await _options(authorized));
  }

  Future<Response<dynamic>> delete(
    String path, {
    bool authorized = false,
  }) async {
    return _dio.delete(path, options: await _options(authorized));
  }

  Future<Options?> _options(bool authorized) async {
    if (!authorized) {
      return null;
    }

    final token = await _tokenStorage.readToken();
    return Options(headers: {'Authorization': 'Bearer $token'});
  }
}
