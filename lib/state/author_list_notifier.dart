import 'package:flutter/foundation.dart';
import '../models/author.dart';
import '../models/author_query.dart';
import '../models/page_result.dart';
import '../repositories/author_repository.dart';
import 'book_list_notifier.dart';

class AuthorListNotifier extends ChangeNotifier {
  final AuthorRepository _repository;
  bool _disposed = false;

  AuthorListNotifier(this._repository);

  AuthorQuery _query = const AuthorQuery();
  PageResult<Author> _result = PageResult.empty();
  LoadStatus _status = LoadStatus.idle;
  String? _error;
  final Set<int> _selected = {};

  AuthorQuery get query => _query;
  PageResult<Author> get result => _result;
  LoadStatus get status => _status;
  String? get error => _error;
  Set<int> get selected => Set.unmodifiable(_selected);
  bool get hasSelection => _selected.isNotEmpty;

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> load() async {
    _status = LoadStatus.loading;
    _error = null;
    _safeNotify();

    try {
      _result = await _repository.find(_query);
      _status = LoadStatus.success;
    } catch (e) {
      _error = 'Не удалось загрузить авторов: $e';
      _status = LoadStatus.error;
    }
    _safeNotify();
  }

  Future<void> applyQuery(AuthorQuery next) async {
    if (_query == next) return;
    _query = next;
    _selected.clear();
    await load();
  }

  void toggleSelection(int id) {
    if (_selected.contains(id)) {
      _selected.remove(id);
    } else {
      _selected.add(id);
    }
    _safeNotify();
  }

  void toggleSelectAll(bool? selectAll) {
    if (selectAll == true) {
      _selected.addAll(_result.items.map((a) => a.id));
    } else {
      _selected.clear();
    }
    _safeNotify();
  }

  Future<void> deleteSelected() async {
    if (_selected.isEmpty) return;
    await _repository.deleteMany(_selected.toList());
    _selected.clear();
    await load();
  }

  Future<void> softDelete(int id) async {
    await _repository.softDelete(id);
    await load();
  }

  Future<void> hardDelete(int id) async {
    await _repository.hardDelete(id);
    await load();
  }

  Future<void> restore(int id) async {
    await _repository.restore(id);
    await load();
  }
}
