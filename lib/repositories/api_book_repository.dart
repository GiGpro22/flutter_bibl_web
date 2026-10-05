import 'package:dio/dio.dart';
import '../core/api_exceptions.dart';
import '../models/book.dart';
import '../models/page_result.dart';

class ApiBookRepository {
  final Dio _dio;
  ApiBookRepository(this._dio);

  Future<PageResult<Book>> find({
    String search = '',
    String sort = 'title,asc',
    int page = 1,
    int size = 5,
    bool includeDeleted = false,
    CancelToken? cancelToken,
    int? simulateFail,
    int? simulateDelay,
  }) => guard(() async {
    final response = await _dio.get('/books',
      queryParameters: {
        if (search.trim().isNotEmpty) 'search': search.trim(),
        'sort': sort,
        'page': page,
        'size': size,
        if (includeDeleted) 'includeDeleted': true,
        if (simulateFail != null) '__fail': simulateFail,
        if (simulateDelay != null) '__delay': simulateDelay,
      },
      cancelToken: cancelToken,
    );
    final data = response.data as Map<String, dynamic>;
    return PageResult(
      items: (data['items'] as List)
          .whereType<Map<String, dynamic>>()
          .map(Book.fromJson)
          .toList(),
      page: data['page'] as int? ?? page,
      size: data['size'] as int? ?? size,
      total: data['total'] as int? ?? 0,
    );
  });

  Future<Book> create(Book book) => guard(() async {
    final response = await _dio.post('/books', data: {
      'title': book.title,
      'isbn': book.isbn,
      'year': book.year,
      'pages': book.pages,
      'publisherId': book.publisherId,
      'authorIds': book.authorIds,
      'genreIds': book.genreIds,
      'copiesTotal': book.copiesTotal,
    });
    return Book.fromJson(response.data as Map<String, dynamic>);
  });

  Future<Book> update(Book book) => guard(() async {
    final response = await _dio.put('/books/${book.id}', data: {
      'title': book.title,
      'isbn': book.isbn,
      'year': book.year,
      'pages': book.pages,
      'publisherId': book.publisherId,
      'authorIds': book.authorIds,
      'genreIds': book.genreIds,
      'copiesTotal': book.copiesTotal,
    });
    return Book.fromJson(response.data as Map<String, dynamic>);
  });

  Future<void> softDelete(int id) => guard(() => _dio.delete('/books/$id'));
  Future<void> restore(int id) => guard(() => _dio.post('/books/$id/restore'));
  Future<void> hardDelete(int id) => guard(() => _dio.delete('/books/$id', queryParameters: {'hard': true}));
  Future<int> deleteMany(List<int> ids) => guard(() async {
    final res = await _dio.post('/books/bulk-delete', data: {'ids': ids});
    return (res.data as Map<String, dynamic>)['deleted'] as int? ?? 0;
  });
}