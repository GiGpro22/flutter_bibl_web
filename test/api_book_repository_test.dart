import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:library_catalog/core/api_client.dart';
import 'package:library_catalog/core/api_exceptions.dart';
import 'package:library_catalog/repositories/api_book_repository.dart';

class MockHttpAdapter implements HttpClientAdapter {
  ResponseBody Function(RequestOptions options)? handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (handler != null) return handler!(options);
    return ResponseBody.fromString(
      '{"items":[], "total":0, "page":1, "size":5}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Dio dio;
  late MockHttpAdapter mockAdapter;
  late ApiBookRepository repo;

  setUp(() {
    dio = buildDio();
    mockAdapter = MockHttpAdapter();
    dio.httpClientAdapter = mockAdapter;
    repo = ApiBookRepository(dio);
  });

  test('1. Успешный парсинг списка книг из PageResult', () async {
    mockAdapter.handler = (opt) => ResponseBody.fromString(
      '{"items":[{"id":1,"title":"Тест","isbn":"123"}],"total":1,"page":1,"size":5}',
      200,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );

    final res = await repo.find();
    expect(res.items.length, 1);
    expect(res.items.first.title, 'Тест');
    expect(res.total, 1);
  });

  test('2. Разбор ошибки 422 в ValidationException с картой полей', () async {
    mockAdapter.handler = (opt) => ResponseBody.fromString(
      '{"message":"Ошибка валидации","errors":{"isbn":"ISBN занят"}}',
      422,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );

    expect(
      () => repo.find(),
      throwsA(isA<ValidationException>().having((e) => e.errors['isbn'], 'isbn', 'ISBN занят')),
    );
  });

  test('3. Разбор ошибки 409 в ConflictException', () async {
    mockAdapter.handler = (opt) => ResponseBody.fromString(
      '{"message":"Нет доступных экземпляров"}',
      409,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );

    expect(
      () => repo.find(),
      throwsA(isA<ConflictException>().having((e) => e.message, 'message', 'Нет доступных экземпляров')),
    );
  });

  test('4. Сетевой сбой преобразуется в NetworkException', () async {
    mockAdapter.handler = (opt) {
      throw DioException(
        requestOptions: opt,
        type: DioExceptionType.connectionError,
      );
    };

    expect(() => repo.find(), throwsA(isA<NetworkException>()));
  });

  test('5. Отмена запроса CancelToken преобразуется в NetworkException', () async {
    final token = CancelToken();
    mockAdapter.handler = (opt) {
      throw DioException(
        requestOptions: opt,
        type: DioExceptionType.cancel,
      );
    };

    expect(
      () => repo.find(cancelToken: token),
      throwsA(isA<NetworkException>().having((e) => e.message, 'message', contains('отменён'))),
    );
  });
}