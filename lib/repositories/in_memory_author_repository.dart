import '../models/author.dart';
import '../models/author_query.dart';
import '../models/page_result.dart';
import 'author_repository.dart';

final List<Author> seedAuthors = [
  const Author(id: 1, name: 'Лев Толстой', country: 'Россия', birthYear: 1828),
  const Author(id: 2, name: 'Фёдор Достоевский', country: 'Россия', birthYear: 1821),
  const Author(id: 3, name: 'Михаил Булгаков', country: 'СССР', birthYear: 1891),
  const Author(id: 4, name: 'Джордж Оруэлл', country: 'Великобритания', birthYear: 1903),
  const Author(id: 5, name: 'Олдос Хаксли', country: 'Великобритания', birthYear: 1894),
  const Author(id: 6, name: 'Агата Кристи', country: 'Великобритания', birthYear: 1890),
  const Author(id: 7, name: 'Артур Конан Дойл', country: 'Великобритания', birthYear: 1859),
  const Author(id: 8, name: 'Роберт Мартин', country: 'США', birthYear: 1952),
];

class InMemoryAuthorRepository implements AuthorRepository {
  final List<Author> _authors = [...seedAuthors];

  @override
  Future<PageResult<Author>> find(AuthorQuery q) async {
    await Future.delayed(const Duration(milliseconds: 200));
    var rows = _authors.where((a) => q.includeDeleted || !a.isDeleted).toList();

    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where((a) =>
              a.name.toLowerCase().contains(needle) ||
              a.country.toLowerCase().contains(needle))
          .toList();
    }
    if (q.country != null && q.country!.isNotEmpty) {
      rows = rows.where((a) => a.country == q.country).toList();
    }

    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'birthYear' => a.birthYear.compareTo(b.birthYear),
        'country' => a.country.compareTo(b.country),
        _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Author>[] : rows.sublist(from, to);

    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<Author?> findById(int id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final i = _authors.indexWhere((a) => a.id == id);
    return i != -1 ? _authors[i] : null;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _authors.indexWhere((a) => a.id == id);
    if (i == -1) throw StateError('Автор $id не найден');
    _authors[i] = _authors[i].copyWith(deletedAt: DateTime.now());
  }

  @override
  Future<void> hardDelete(int id) async {
    _authors.removeWhere((a) => a.id == id);
  }

  @override
  Future<void> restore(int id) async {
    final i = _authors.indexWhere((a) => a.id == id);
    if (i == -1) throw StateError('Автор $id не найден');
    _authors[i] = _authors[i].copyWith(clearDeletedAt: true);
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _authors.indexWhere((a) => a.id == id && !a.isDeleted);
      if (i != -1) {
        _authors[i] = _authors[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    return count;
  }
}
