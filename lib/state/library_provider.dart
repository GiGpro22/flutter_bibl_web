import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/author.dart';
import '../models/genre.dart';
import '../models/publisher.dart';
import '../models/reader.dart';
import '../models/book.dart';

class LibraryProvider extends ChangeNotifier {
  static const _versionKey = 'app_schema_version';
  static const int currentVersion = 2;

  final SharedPreferences _prefs;

  List<Author> _authors = [];
  List<Genre> _genres = [];
  List<Publisher> _publishers = [];
  List<Reader> _readers = [];
  List<Book> _books = [];

  LibraryProvider(this._prefs) {
    _initStorageWithMigration();
  }

  List<Author> get authors => _authors;
  List<Genre> get genres => _genres;
  List<Publisher> get publishers => _publishers;
  List<Reader> get readers => _readers;
  List<Book> get books => _books;

  void _initStorageWithMigration() {
    final storedVersion = _prefs.getInt(_versionKey) ?? 1;

    // Миграция схем данных без падений приложения
    if (storedVersion < currentVersion) {
      _migrateV1ToV2();
      _prefs.setInt(_versionKey, currentVersion);
    }

    _restoreAll();
  }

  void _migrateV1ToV2() {
    // Безопасное добавление поддерживаемых жанров в издательства
    final rawPubs = _prefs.getString('publishers_v1');
    if (rawPubs != null) {
      try {
        final list = jsonDecode(rawPubs) as List;
        final migrated = list.map((item) {
          final map = item as Map<String, dynamic>;
          if (!map.containsKey('supportedGenreIds')) {
            map['supportedGenreIds'] = [1, 2, 3];
          }
          return map;
        }).toList();
        _prefs.setString('publishers_v2', jsonEncode(migrated));
      } catch (_) {}
    }
  }

  void _restoreAll() {
    _authors = _restoreList('authors_v2', (j) => Author.fromJson(j), _seedAuthors);
    _genres = _restoreList('genres_v2', (j) => Genre.fromJson(j), _seedGenres);
    _publishers = _restoreList('publishers_v2', (j) => Publisher.fromJson(j), _seedPublishers);
    _readers = _restoreList('readers_v2', (j) => Reader.fromJson(j), _seedReaders);
    _books = _restoreList('books_v2', (j) => Book.fromJson(j), _seedBooks);
  }

  List<T> _restoreList<T>(String key, T Function(Map<String, dynamic>) fromJson, List<T> seed) {
    final raw = _prefs.getString(key);
    if (raw == null) {
      _persist(key, seed);
      return [...seed];
    }
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      _persist(key, seed);
      return [...seed];
    }
  }

  Future<void> _persist(String key, List<dynamic> items) async {
    final data = jsonEncode(items.map((e) => e.toJson()).toList());
    await _prefs.setString(key, data);
  }

  // --- Проверки уникальности ---
  bool isIsbnFree(String isbn, {int? exceptId}) {
    final clean = isbn.trim().toLowerCase();
    if (clean.isEmpty) return true;
    return !_books.any((b) => !b.isDeleted && b.id != exceptId && b.isbn.trim().toLowerCase() == clean);
  }

  bool isReaderEmailFree(String email, {int? exceptId}) {
    final clean = email.trim().toLowerCase();
    if (clean.isEmpty) return true;
    return !_readers.any((r) => !r.isDeleted && r.id != exceptId && r.email.trim().toLowerCase() == clean);
  }

  int getLinkedBooksCountForPublisher(int publisherId) {
    return _books.where((b) => !b.isDeleted && b.publisherId == publisherId).length;
  }

  // --- Мягкое и физическое удаление для всех сущностей ---
  Future<void> softDeleteBook(int id) async {
    final idx = _books.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _books[idx] = _books[idx].copyWith(deletedAt: DateTime.now());
      await _persist('books_v2', _books);
      notifyListeners();
    }
  }

  Future<void> restoreBook(int id) async {
    final idx = _books.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _books[idx] = _books[idx].copyWith(clearDeletedAt: true);
      await _persist('books_v2', _books);
      notifyListeners();
    }
  }

  Future<void> hardDeleteBook(int id) async {
    _books.removeWhere((e) => e.id == id);
    await _persist('books_v2', _books);
    notifyListeners();
  }

  Future<void> softDeleteAuthor(int id) async {
    final idx = _authors.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _authors[idx] = _authors[idx].copyWith(deletedAt: DateTime.now());
      await _persist('authors_v2', _authors);
      notifyListeners();
    }
  }

  Future<void> restoreAuthor(int id) async {
    final idx = _authors.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _authors[idx] = _authors[idx].copyWith(clearDeletedAt: true);
      await _persist('authors_v2', _authors);
      notifyListeners();
    }
  }

  Future<void> hardDeleteAuthor(int id) async {
    _authors.removeWhere((e) => e.id == id);
    await _persist('authors_v2', _authors);
    notifyListeners();
  }

  Future<void> softDeleteGenre(int id) async {
    final idx = _genres.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _genres[idx] = _genres[idx].copyWith(deletedAt: DateTime.now());
      await _persist('genres_v2', _genres);
      notifyListeners();
    }
  }

  Future<void> restoreGenre(int id) async {
    final idx = _genres.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _genres[idx] = _genres[idx].copyWith(clearDeletedAt: true);
      await _persist('genres_v2', _genres);
      notifyListeners();
    }
  }

  Future<void> hardDeleteGenre(int id) async {
    _genres.removeWhere((e) => e.id == id);
    await _persist('genres_v2', _genres);
    notifyListeners();
  }

  Future<void> softDeletePublisher(int id) async {
    final idx = _publishers.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _publishers[idx] = _publishers[idx].copyWith(deletedAt: DateTime.now());
      await _persist('publishers_v2', _publishers);
      notifyListeners();
    }
  }

  Future<void> restorePublisher(int id) async {
    final idx = _publishers.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _publishers[idx] = _publishers[idx].copyWith(clearDeletedAt: true);
      await _persist('publishers_v2', _publishers);
      notifyListeners();
    }
  }

  Future<void> hardDeletePublisher(int id) async {
    _publishers.removeWhere((e) => e.id == id);
    await _persist('publishers_v2', _publishers);
    notifyListeners();
  }

  Future<void> softDeleteReader(int id) async {
    final idx = _readers.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _readers[idx] = _readers[idx].copyWith(deletedAt: DateTime.now());
      await _persist('readers_v2', _readers);
      notifyListeners();
    }
  }

  Future<void> restoreReader(int id) async {
    final idx = _readers.indexWhere((e) => e.id == id);
    if (idx != -1) {
      _readers[idx] = _readers[idx].copyWith(clearDeletedAt: true);
      await _persist('readers_v2', _readers);
      notifyListeners();
    }
  }

  Future<void> hardDeleteReader(int id) async {
    _readers.removeWhere((e) => e.id == id);
    await _persist('readers_v2', _readers);
    notifyListeners();
  }

  // --- Сохранение ---
  Future<void> saveBook(Book book) async {
    if (book.id == 0) {
      final newId = _books.isEmpty ? 1 : (_books.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1);
      _books.add(book.copyWith(id: newId));
    } else {
      final idx = _books.indexWhere((e) => e.id == book.id);
      if (idx != -1) _books[idx] = book;
    }
    await _persist('books_v2', _books);
    notifyListeners();
  }

  Future<void> saveAuthor(Author author) async {
    if (author.id == 0) {
      final newId = _authors.isEmpty ? 1 : (_authors.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1);
      _authors.add(author.copyWith(id: newId));
    } else {
      final idx = _authors.indexWhere((e) => e.id == author.id);
      if (idx != -1) _authors[idx] = author;
    }
    await _persist('authors_v2', _authors);
    notifyListeners();
  }

  Future<void> saveGenre(Genre genre) async {
    if (genre.id == 0) {
      final newId = _genres.isEmpty ? 1 : (_genres.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1);
      _genres.add(genre.copyWith(id: newId));
    } else {
      final idx = _genres.indexWhere((e) => e.id == genre.id);
      if (idx != -1) _genres[idx] = genre;
    }
    await _persist('genres_v2', _genres);
    notifyListeners();
  }

  Future<void> savePublisher(Publisher publisher) async {
    if (publisher.id == 0) {
      final newId = _publishers.isEmpty ? 1 : (_publishers.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1);
      _publishers.add(publisher.copyWith(id: newId));
    } else {
      final idx = _publishers.indexWhere((e) => e.id == publisher.id);
      if (idx != -1) _publishers[idx] = publisher;
    }
    await _persist('publishers_v2', _publishers);
    notifyListeners();
  }

  Future<void> saveReader(Reader reader) async {
    if (reader.id == 0) {
      final newId = _readers.isEmpty ? 1 : (_readers.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1);
      _readers.add(reader.copyWith(id: newId));
    } else {
      final idx = _readers.indexWhere((e) => e.id == reader.id);
      if (idx != -1) _readers[idx] = reader;
    }
    await _persist('readers_v2', _readers);
    notifyListeners();
  }

  // --- Начальные сиды ---
  static final _seedPublishers = [
    const Publisher(id: 1, name: 'Эксмо', city: 'Москва', supportedGenreIds: [1, 2, 3]),
    const Publisher(id: 2, name: 'Питер', city: 'Санкт-Петербург', supportedGenreIds: [2]),
    const Publisher(id: 3, name: 'АСТ', city: 'Москва', supportedGenreIds: [1, 3]),
  ];

  static final _seedAuthors = [
    const Author(id: 1, name: 'Лев Толстой', country: 'Россия', birthYear: 1828, biography: 'Русский писатель'),
    const Author(id: 2, name: 'Федор Достоевский', country: 'Россия', birthYear: 1821, biography: 'Классик русской литературы'),
    const Author(id: 3, name: 'Джордж Оруэлл', country: 'Великобритания', birthYear: 1903, biography: 'Английский писатель'),
  ];

  static final _seedGenres = [
    const Genre(id: 1, name: 'Классика', description: 'Классическая литература'),
    const Genre(id: 2, name: 'Фантастика', description: 'Научная фантастика'),
    const Genre(id: 3, name: 'Роман', description: 'Художественные романы'),
  ];

  static final _seedReaders = [
    Reader(
      id: 1,
      fullName: 'Иванов Иван Иванович',
      email: 'ivanov@example.com',
      phone: '+7 999 111-22-33',
      card: LibraryCard(cardNumber: 'CARD-1001', issueDate: DateTime.now().subtract(const Duration(days: 30))),
    ),
  ];

  static final _seedBooks = [
    const Book(
      id: 1,
      title: 'Война и мир',
      isbn: '978-5-699-12014-7',
      year: 1869,
      pages: 1225,
      publisherId: 1,
      authorIds: [1],
      genreIds: [1, 3],
      copiesTotal: 5,
      copiesAvailable: 3,
    ),
    const Book(
      id: 2,
      title: '1984',
      isbn: '978-5-17-080115-3',
      year: 1949,
      pages: 328,
      publisherId: 2,
      authorIds: [3],
      genreIds: [2],
      copiesTotal: 10,
      copiesAvailable: 7,
    ),
  ];
}
