import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../core/api_exceptions.dart';
import '../models/author.dart';
import '../models/genre.dart';
import '../models/publisher.dart';
import '../models/reader.dart';
import '../models/book.dart';
import '../repositories/api_book_repository.dart';

enum PageStatus { loading, success, empty, error }

class LibraryProvider extends ChangeNotifier {
  final Dio _dio;
  late final ApiBookRepository bookRepo;

  LibraryProvider(this._dio) {
    bookRepo = ApiBookRepository(_dio);
    refreshAll();
  }

  // Состояние книг (REST API)
  PageStatus bookStatus = PageStatus.loading;
  String bookError = '';
  List<Book> books = [];
  int bookPage = 1;
  int bookTotalPages = 1;
  int bookTotal = 0;
  String bookSearch = '';
  String bookSort = 'title,asc';
  bool bookShowDeleted = false;
  CancelToken? _searchCancelToken;

  // Справочники (кэшируются)
  List<Author> authors = [];
  List<Genre> genres = [];
  List<Publisher> publishers = [];
  List<Reader> readers = [];
  bool _dictionariesLoaded = false;

  Future<void> refreshAll() async {
    await fetchDictionaries();
    await fetchBooks();
  }

  Future<void> fetchDictionaries({bool force = false}) async {
    if (_dictionariesLoaded && !force) return;
    try {
      final res = await Future.wait([
        _dio.get('/authors'),
        _dio.get('/genres'),
        _dio.get('/publishers'),
        _dio.get('/readers'),
      ]);

      authors = ((res[0].data as Map)['items'] as List)
          .map((e) => Author.fromJson(e as Map<String, dynamic>)).toList();
      genres = ((res[1].data as Map)['items'] as List)
          .map((e) => Genre.fromJson(e as Map<String, dynamic>)).toList();
      publishers = ((res[2].data as Map)['items'] as List)
          .map((e) => Publisher.fromJson(e as Map<String, dynamic>)).toList();
      readers = ((res[3].data as Map)['items'] as List)
          .map((e) => Reader.fromJson(e as Map<String, dynamic>)).toList();

      _dictionariesLoaded = true;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchBooks({int? simulateFail, int? simulateDelay}) async {
    _searchCancelToken?.cancel();
    _searchCancelToken = CancelToken();

    bookStatus = PageStatus.loading;
    bookError = '';
    notifyListeners();

    try {
      final result = await bookRepo.find(
        search: bookSearch,
        sort: bookSort,
        page: bookPage,
        size: 5,
        includeDeleted: bookShowDeleted,
        cancelToken: _searchCancelToken,
        simulateFail: simulateFail,
        simulateDelay: simulateDelay,
      );

      books = result.items;
      bookTotal = result.total;
      bookTotalPages = result.totalPages == 0 ? 1 : result.totalPages;
      bookStatus = books.isEmpty ? PageStatus.empty : PageStatus.success;
    } on ApiException catch (e) {
      if (e is NetworkException && e.message.contains('отменён')) return;
      bookStatus = PageStatus.error;
      bookError = e.message;
    } catch (e) {
      bookStatus = PageStatus.error;
      bookError = e.toString();
    }
    notifyListeners();
  }

  void onSearchChanged(String query) {
    bookSearch = query;
    bookPage = 1;
    fetchBooks();
  }

  void onSortChanged(String sort) {
    bookSort = sort;
    bookPage = 1;
    fetchBooks();
  }

  void onToggleDeleted(bool val) {
    bookShowDeleted = val;
    bookPage = 1;
    fetchBooks();
  }

  void setPage(int page) {
    if (page < 1 || page > bookTotalPages) return;
    bookPage = page;
    fetchBooks();
  }

  // --- CRUD для Книг ---
  Future<void> saveBook(Book book) async {
    if (book.id == 0) {
      await bookRepo.create(book);
    } else {
      await bookRepo.update(book);
    }
    await fetchBooks();
  }

  Future<void> softDeleteBook(int id) async {
    await bookRepo.softDelete(id);
    await fetchBooks();
  }

  Future<void> restoreBook(int id) async {
    await bookRepo.restore(id);
    await fetchBooks();
  }

  Future<void> hardDeleteBook(int id) async {
    await bookRepo.hardDelete(id);
    await fetchBooks();
  }

  // --- CRUD для Авторов ---
  Future<void> saveAuthor(Author author) async {
    if (author.id == 0) {
      final newId = authors.isEmpty ? 1 : (authors.map((a) => a.id).reduce((a, b) => a > b ? a : b) + 1);
      authors.add(author.copyWith(id: newId));
    } else {
      final idx = authors.indexWhere((a) => a.id == author.id);
      if (idx != -1) authors[idx] = author;
    }
    notifyListeners();
  }

  Future<void> deleteAuthor(int id) async {
    authors.removeWhere((a) => a.id == id);
    notifyListeners();
  }

  // --- CRUD для Жанров ---
  Future<void> saveGenre(Genre genre) async {
    if (genre.id == 0) {
      final newId = genres.isEmpty ? 1 : (genres.map((g) => g.id).reduce((a, b) => a > b ? a : b) + 1);
      genres.add(genre.copyWith(id: newId));
    } else {
      final idx = genres.indexWhere((g) => g.id == genre.id);
      if (idx != -1) genres[idx] = genre;
    }
    notifyListeners();
  }

  Future<void> deleteGenre(int id) async {
    genres.removeWhere((g) => g.id == id);
    notifyListeners();
  }

  // --- CRUD для Издательств ---
  Future<void> savePublisher(Publisher publisher) async {
    if (publisher.id == 0) {
      final newId = publishers.isEmpty ? 1 : (publishers.map((p) => p.id).reduce((a, b) => a > b ? a : b) + 1);
      publishers.add(publisher.copyWith(id: newId));
    } else {
      final idx = publishers.indexWhere((p) => p.id == publisher.id);
      if (idx != -1) publishers[idx] = publisher;
    }
    notifyListeners();
  }

  Future<void> deletePublisher(int id) async {
    publishers.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  // --- CRUD для Читателей ---
  Future<void> saveReader(Reader reader) async {
    if (reader.id == 0) {
      final newId = readers.isEmpty ? 1 : (readers.map((r) => r.id).reduce((a, b) => a > b ? a : b) + 1);
      readers.add(reader.copyWith(id: newId));
    } else {
      final idx = readers.indexWhere((r) => r.id == reader.id);
      if (idx != -1) readers[idx] = reader;
    }
    notifyListeners();
  }

  Future<void> deleteReader(int id) async {
    readers.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  // --- Проверки уникальности и связей ---
  bool isReaderEmailFree(String email, {int? exceptId}) {
    final clean = email.trim().toLowerCase();
    if (clean.isEmpty) return true;
    return !readers.any((r) => r.id != exceptId && r.email.trim().toLowerCase() == clean);
  }

  bool isIsbnFree(String isbn, {int? exceptId}) {
    final clean = isbn.trim().toLowerCase();
    if (clean.isEmpty) return true;
    return !books.any((b) => b.id != exceptId && b.isbn.trim().toLowerCase() == clean);
  }

  int getLinkedBooksCountForPublisher(int pubId) {
    return books.where((b) => b.publisherId == pubId).length;
  }
}
