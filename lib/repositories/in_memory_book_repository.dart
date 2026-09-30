import '../models/book.dart';
import '../models/book_query.dart';
import '../models/page_result.dart';
import 'book_repository.dart';

final List<Book> seedBooks = [
  const Book(id: 1, title: 'Война и мир', isbn: '978-5-17-090334-4', year: 1869, pages: 1225, publisherId: 1, authorIds: [1], genreIds: [3, 5], copiesTotal: 5, copiesAvailable: 3),
  const Book(id: 2, title: 'Преступление и наказание', isbn: '978-5-389-06256-6', year: 1866, pages: 672, publisherId: 3, authorIds: [2], genreIds: [3, 5], copiesTotal: 4, copiesAvailable: 2),
  const Book(id: 3, title: 'Идиот', isbn: '978-5-17-087889-5', year: 1869, pages: 640, publisherId: 1, authorIds: [2], genreIds: [3, 5], copiesTotal: 3, copiesAvailable: 1),
  const Book(id: 4, title: 'Мастер и Маргарита', isbn: '978-5-389-01686-6', year: 1967, pages: 512, publisherId: 3, authorIds: [3], genreIds: [1, 5], copiesTotal: 6, copiesAvailable: 5),
  const Book(id: 5, title: 'Собачье сердце', isbn: '978-5-17-045123-8', year: 1925, pages: 192, publisherId: 1, authorIds: [3], genreIds: [1, 5], copiesTotal: 4, copiesAvailable: 4),
  const Book(id: 6, title: '1984', isbn: '978-5-17-080115-2', year: 1949, pages: 320, publisherId: 1, authorIds: [4], genreIds: [1], copiesTotal: 8, copiesAvailable: 3),
  const Book(id: 7, title: 'Скотный двор', isbn: '978-5-17-098765-1', year: 1945, pages: 128, publisherId: 1, authorIds: [4], genreIds: [1], copiesTotal: 5, copiesAvailable: 5),
  const Book(id: 8, title: 'О дивный новый мир', isbn: '978-5-17-099432-8', year: 1932, pages: 352, publisherId: 1, authorIds: [5], genreIds: [1], copiesTotal: 4, copiesAvailable: 0),
  const Book(id: 9, title: 'Убийство в Восточном экспрессе', isbn: '978-5-699-79289-3', year: 1934, pages: 320, publisherId: 2, authorIds: [6], genreIds: [2], copiesTotal: 5, copiesAvailable: 4),
  const Book(id: 10, title: 'Десять негритят', isbn: '978-5-04-098761-2', year: 1939, pages: 288, publisherId: 2, authorIds: [6], genreIds: [2], copiesTotal: 4, copiesAvailable: 1),
  const Book(id: 11, title: 'Этюд в багровых тонах', isbn: '978-5-389-04567-5', year: 1887, pages: 224, publisherId: 3, authorIds: [7], genreIds: [2, 5], copiesTotal: 3, copiesAvailable: 2),
  const Book(id: 12, title: 'Собака Баскервилей', isbn: '978-5-389-08912-9', year: 1902, pages: 256, publisherId: 3, authorIds: [7], genreIds: [2, 5], copiesTotal: 5, copiesAvailable: 5),
  const Book(id: 13, title: 'Чистый код', isbn: '978-5-4461-0960-9', year: 2008, pages: 464, publisherId: 4, authorIds: [8], genreIds: [4], copiesTotal: 7, copiesAvailable: 6),
  const Book(id: 14, title: 'Идеальный программист', isbn: '978-5-496-00447-3', year: 2011, pages: 224, publisherId: 4, authorIds: [8], genreIds: [4], copiesTotal: 3, copiesAvailable: 3),
  const Book(id: 15, title: 'Анна Каренина', isbn: '978-5-17-090335-1', year: 1877, pages: 864, publisherId: 1, authorIds: [1], genreIds: [3, 5], copiesTotal: 3, copiesAvailable: 1),
  const Book(id: 16, title: 'Братья Карамазовы', isbn: '978-5-389-06257-3', year: 1880, pages: 896, publisherId: 3, authorIds: [2], genreIds: [3, 5], copiesTotal: 4, copiesAvailable: 2),
  const Book(id: 17, title: 'Белая гвардия', isbn: '978-5-389-01687-3', year: 1925, pages: 384, publisherId: 3, authorIds: [3], genreIds: [3, 5], copiesTotal: 2, copiesAvailable: 0),
  const Book(id: 18, title: 'Памяти Каталонии', isbn: '978-5-17-080116-9', year: 1938, pages: 288, publisherId: 1, authorIds: [4], genreIds: [4], copiesTotal: 2, copiesAvailable: 2),
  const Book(id: 19, title: 'Двери восприятия', isbn: '978-5-17-099433-5', year: 1954, pages: 160, publisherId: 1, authorIds: [5], genreIds: [4], copiesTotal: 3, copiesAvailable: 3),
  const Book(id: 20, title: 'Таинственное происшествие в Стайлзе', isbn: '978-5-699-79290-9', year: 1920, pages: 256, publisherId: 2, authorIds: [6], genreIds: [2], copiesTotal: 4, copiesAvailable: 4),
  const Book(id: 21, title: 'Знак четырёх', isbn: '978-5-389-04568-2', year: 1890, pages: 192, publisherId: 3, authorIds: [7], genreIds: [2, 5], copiesTotal: 3, copiesAvailable: 1),
  const Book(id: 22, title: 'Чистая архитектура', isbn: '978-5-4461-0772-8', year: 2017, pages: 352, publisherId: 4, authorIds: [8], genreIds: [4], copiesTotal: 6, copiesAvailable: 4),
];

class InMemoryBookRepository implements BookRepository {
  final List<Book> _books = [...seedBooks];

  @override
  Future<PageResult<Book>> find(BookQuery q) async {
    await Future.delayed(const Duration(milliseconds: 250));
    var rows = _books.where((b) => q.includeDeleted || !b.isDeleted).toList();

    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where((b) =>
              b.title.toLowerCase().contains(needle) ||
              b.isbn.toLowerCase().contains(needle))
          .toList();
    }
    if (q.genreId != null) {
      rows = rows.where((b) => b.genreIds.contains(q.genreId)).toList();
    }
    if (q.publisherId != null) {
      rows = rows.where((b) => b.publisherId == q.publisherId).toList();
    }
    if (q.yearFrom != null) {
      rows = rows.where((b) => b.year >= q.yearFrom!).toList();
    }
    if (q.yearTo != null) {
      rows = rows.where((b) => b.year <= q.yearTo!).toList();
    }

    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'year' => a.year.compareTo(b.year),
        'pages' => a.pages.compareTo(b.pages),
        _ => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Book>[] : rows.sublist(from, to);

    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<Book?> findById(int id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _books.indexWhere((b) => b.id == id);
    return index != -1 ? _books[index] : null;
  }

  @override
  Future<Book> create(Book book) async {
    final nextId = _books.isEmpty ? 1 : _books.map((b) => b.id).reduce((a, b) => a > b ? a : b) + 1;
    final created = book.copyWith();
    final item = Book(
      id: nextId,
      title: created.title,
      isbn: created.isbn,
      year: created.year,
      pages: created.pages,
      publisherId: created.publisherId,
      authorIds: created.authorIds,
      genreIds: created.genreIds,
      copiesTotal: created.copiesTotal,
      copiesAvailable: created.copiesAvailable,
    );
    _books.add(item);
    return item;
  }

  @override
  Future<Book> update(Book book) async {
    final i = _books.indexWhere((b) => b.id == book.id);
    if (i == -1) throw StateError('Книга ${book.id} не найдена');
    _books[i] = book;
    return book;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _books.indexWhere((b) => b.id == id);
    if (i == -1) throw StateError('Книга $id не найдена');
    _books[i] = _books[i].copyWith(deletedAt: DateTime.now());
  }

  @override
  Future<void> hardDelete(int id) async {
    _books.removeWhere((b) => b.id == id);
  }

  @override
  Future<void> restore(int id) async {
    final i = _books.indexWhere((b) => b.id == id);
    if (i == -1) throw StateError('Книга $id не найдена');
    _books[i] = _books[i].copyWith(clearDeletedAt: true);
  }

  // Ошибка исправлена: b.isDeleted вместо b[i].isDeleted
  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _books.indexWhere((b) => b.id == id && !b.isDeleted);
      if (i != -1) {
        _books[i] = _books[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    return count;
  }
}
