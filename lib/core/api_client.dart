import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'config.dart';
import 'api_exceptions.dart';

Dio buildDio({String? Function()? tokenProvider}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = tokenProvider?.call();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        if (kDebugMode) {
          debugPrint('[API] ${options.method} -> ${options.uri}');
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        final status = response.statusCode ?? 0;
        if (kDebugMode) {
          debugPrint('[API] [$status] <- ${response.requestOptions.uri}');
        }
        if (status >= 400) {
          return handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              error: mapHttpError(status, response.data),
            ),
            true,
          );
        }
        return handler.next(response);
      },
      onError: (error, handler) async {
        if (kDebugMode) {
          debugPrint('[API СБОЙ] ${error.requestOptions.uri}: ${error.type}');
        }

        // Автоповтор (Retry): до 3 попыток только для GET
        final req = error.requestOptions;
        if (req.method.toUpperCase() == 'GET' &&
            (error.type == DioExceptionType.connectionError ||
             error.type == DioExceptionType.connectionTimeout)) {
          int retries = req.extra['retry_count'] ?? 0;
          if (retries < 3) {
            retries++;
            req.extra['retry_count'] = retries;
            final delay = Duration(milliseconds: 500 * (1 << (retries - 1)));
            if (kDebugMode) {
              debugPrint('[API Retry] Повтор запроса ($retries/3) через ${delay.inMilliseconds}мс...');
            }
            await Future.delayed(delay);
            try {
              final response = await dio.fetch(req);
              return handler.resolve(response);
            } catch (e) {
              if (e is DioException) return handler.next(e);
            }
          }
        }
        return handler.next(error);
      },
    ),
  );

  return dio;
}
