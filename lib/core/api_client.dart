import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'config.dart';
import 'api_exceptions.dart';
import 'token_holder.dart';

Dio buildDio({Future<void> Function()? onSessionExpired}) {
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
        final token = globalTokens.accessToken;
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
        final status = error.response?.statusCode;
        final path = error.requestOptions.path;

        // 1. Тихое обновление токена (Silent Refresh) при 401 (ПР5)
        if (status == 401 && !path.contains('/auth/')) {
          final refresh = globalTokens.refreshToken;
          if (refresh != null) {
            try {
              if (kDebugMode) debugPrint('[API] Токен истек. Выполняем silent refresh...');
              final refreshDio = Dio(BaseOptions(baseUrl: apiBaseUrl));
              final refreshRes = await refreshDio.post('/auth/refresh', data: {'refreshToken': refresh});
              final newAccess = refreshRes.data['accessToken'] as String;

              globalTokens.accessToken = newAccess;

              final retryOptions = error.requestOptions;
              retryOptions.headers['Authorization'] = 'Bearer $newAccess';
              final response = await dio.fetch(retryOptions);
              return handler.resolve(response);
            } catch (e) {
              if (kDebugMode) debugPrint('[API] Silent refresh не удался, завершаем сессию.');
              globalTokens.clear();
              await onSessionExpired?.call();
            }
          } else {
            await onSessionExpired?.call();
          }
        }

        // 2. Автоматический повтор при сетевом сбое (ПР4, оценка «5»)
        final isGet = error.requestOptions.method.toUpperCase() == 'GET';
        final isNetworkError = error.type == DioExceptionType.connectionError ||
                               error.type == DioExceptionType.connectionTimeout ||
                               error.type == DioExceptionType.sendTimeout ||
                               error.type == DioExceptionType.receiveTimeout;

        int retryCount = error.requestOptions.extra['retry_count'] ?? 0;
        if (isGet && isNetworkError && retryCount < 3) {
          retryCount++;
          error.requestOptions.extra['retry_count'] = retryCount;
          final delayMs = retryCount * 500;
          if (kDebugMode) {
            debugPrint('[API] Сетевой сбой GET (${error.requestOptions.uri}). Попытка $retryCount из 3 через $delayMs мс...');
          }
          await Future.delayed(Duration(milliseconds: delayMs));
          try {
            final response = await dio.fetch(error.requestOptions);
            return handler.resolve(response);
          } on DioException catch (e) {
            return handler.next(e);
          } catch (_) {}
        }

        return handler.next(error);
      },
    ),
  );

  return dio;
}