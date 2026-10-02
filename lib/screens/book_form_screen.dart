import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/validators.dart';
import '../models/book.dart';
import '../models/publisher.dart';
import '../state/library_provider.dart';
import '../widgets/entity_form_scaffold.dart';

class BookFormScreen extends StatefulWidget {
  final int? id;
  const BookFormScreen({super.key, this.id});

  bool get isEditing => id != null;

  @override
  State<BookFormScreen> createState() => _BookFormScreenState();
}

class _BookFormScreenState extends State<BookFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _initialized = false;
  bool _isSaving = false;
  bool _isDirty = false;

  final _titleController = TextEditingController();
  final _isbnController = TextEditingController();
  final _yearController = TextEditingController();
  final _pagesController = TextEditingController();
  final _copiesTotalController = TextEditingController();
  final _copiesAvailController = TextEditingController();

  int? _publisherId;
  List<int> _authorIds = [];
  List<int> _genreIds = [];

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;

    if (widget.isEditing) {
      final provider = context.read<LibraryProvider>();
      final book = provider.books.cast<Book?>().firstWhere((b) => b?.id == widget.id, orElse: () => null);
      if (book != null) {
        _titleController.text = book.title;
        _isbnController.text = book.isbn;
        _yearController.text = book.year == 0 ? '' : book.year.toString();
        _pagesController.text = book.pages == 0 ? '' : book.pages.toString();
        _copiesTotalController.text = book.copiesTotal.toString();
        _copiesAvailController.text = book.copiesAvailable.toString();
        _publisherId = book.publisherId == 0 ? null : book.publisherId;
        _authorIds = [...book.authorIds];
        _genreIds = [...book.genreIds];
      }
    }

    _titleController.addListener(_markDirty);
    _isbnController.addListener(_markDirty);
    _yearController.addListener(_markDirty);
    _pagesController.addListener(_markDirty);
    _copiesTotalController.addListener(_markDirty);
    _copiesAvailController.addListener(_markDirty);

    _initialized = true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _isbnController.dispose();
    _yearController.dispose();
    _pagesController.dispose();
    _copiesTotalController.dispose();
    _copiesAvailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    setState(() => _isSaving = true);
    try {
      final provider = context.read<LibraryProvider>();
      final book = Book(
        id: widget.id ?? 0,
        title: _titleController.text.trim(),
        isbn: _isbnController.text.trim(),
        year: int.tryParse(_yearController.text.trim()) ?? 0,
        pages: int.tryParse(_pagesController.text.trim()) ?? 0,
        copiesTotal: int.tryParse(_copiesTotalController.text.trim()) ?? 1,
        copiesAvailable: int.tryParse(_copiesAvailController.text.trim()) ?? 1,
        publisherId: _publisherId ?? 0,
        authorIds: _authorIds,
        genreIds: _genreIds,
      );

      await provider.saveBook(book);
      _isDirty = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.isEditing ? 'Книга обновлена' : 'Книга создана')),
        );
        Navigator.of(context).pop();
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LibraryProvider>();
    final publishers = provider.publishers.where((p) => !p.isDeleted).toList();
    final authors = provider.authors.where((a) => !a.isDeleted).toList();

    // Каскадное поведение: список доступных жанров фильтруется по выбранному издательству
    Publisher? selectedPub;
    if (_publisherId != null) {
      selectedPub = publishers.cast<Publisher?>().firstWhere((p) => p?.id == _publisherId, orElse: () => null);
    }

    final availableGenres = selectedPub == null
        ? provider.genres.where((g) => !g.isDeleted).toList()
        : provider.genres.where((g) => !g.isDeleted && selectedPub!.supportedGenreIds.contains(g.id)).toList();

    return EntityFormScaffold(
      title: widget.isEditing ? 'Редактировать книгу' : 'Новая книга',
      formKey: _formKey,
      isDirty: _isDirty,
      isSaving: _isSaving,
      onSave: _submit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _titleController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(labelText: 'Название книги *', border: OutlineInputBorder()),
            validator: V.combine([V.required(), V.length(min: 2, max: 200)]),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _isbnController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'ISBN *',
              border: OutlineInputBorder(),
              helperText: 'Формат: 978-5-699-12014-7 или 10/13 цифр',
            ),
            validator: (val) {
              final reqErr = V.required()(val);
              if (reqErr != null) return reqErr;
              if (!provider.isIsbnFree(val!, exceptId: widget.id)) {
                return 'Книга с таким ISBN уже существует';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _yearController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Год издания', border: OutlineInputBorder()),
                  validator: V.integer(min: 1450, max: DateTime.now().year + 1),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _pagesController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Страниц', border: OutlineInputBorder()),
                  validator: V.integer(min: 1, max: 10000),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _copiesTotalController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Всего экз. *', border: OutlineInputBorder()),
                  validator: V.combine([V.required(), V.integer(min: 0)]),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _copiesAvailController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Доступно экз. *', border: OutlineInputBorder()),
                  validator: (val) {
                    final err = V.combine([V.required(), V.integer(min: 0)])(val);
                    if (err != null) return err;
                    final total = int.tryParse(_copiesTotalController.text.trim()) ?? 0;
                    final avail = int.tryParse(val!.trim()) ?? 0;
                    if (avail > total) return 'Не больше общего числа';
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // M:1 Издательство с каскадным обновлением списка жанров
          DropdownButtonFormField<int>(
            value: publishers.any((p) => p.id == _publisherId) ? _publisherId : null,
            decoration: const InputDecoration(
              labelText: 'Издательство (сужает доступные жанры) *',
              border: OutlineInputBorder(),
            ),
            items: publishers.map((p) => DropdownMenuItem(value: p.id, child: Text('${p.name} (${p.city})'))).toList(),
            onChanged: (val) {
              _markDirty();
              setState(() {
                _publisherId = val;
                // Сужение списка: сбрасываем выбранные жанры, если они не поддерживаются издательством
                if (val != null) {
                  final pub = publishers.firstWhere((p) => p.id == val);
                  _genreIds = _genreIds.where((gid) => pub.supportedGenreIds.contains(gid)).toList();
                }
              });
            },
            validator: (val) => val == null ? 'Выберите издательство' : null,
          ),
          const SizedBox(height: 20),
          // M:N Авторы
          FormField<List<int>>(
            initialValue: _authorIds,
            validator: (val) => (val == null || val.isEmpty) ? 'Выберите хотя бы одного автора' : null,
            builder: (field) {
              return InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Авторы *',
                  border: const OutlineInputBorder(),
                  errorText: field.errorText,
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: authors.map((a) {
                    final selected = field.value!.contains(a.id);
                    return FilterChip(
                      label: Text(a.name),
                      selected: selected,
                      onSelected: (_) {
                        _markDirty();
                        final next = [...field.value!];
                        selected ? next.remove(a.id) : next.add(a.id);
                        field.didChange(next);
                        setState(() => _authorIds = next);
                      },
                    );
                  }).toList(),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          // M:N Каскадный выбор жанров
          FormField<List<int>>(
            initialValue: _genreIds,
            validator: (val) => (val == null || val.isEmpty) ? 'Выберите хотя бы один жанр' : null,
            builder: (field) {
              return InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Жанры (каскадно фильтруются издательством) *',
                  border: const OutlineInputBorder(),
                  errorText: field.errorText,
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: availableGenres.map((g) {
                    final selected = _genreIds.contains(g.id);
                    return FilterChip(
                      label: Text(g.name),
                      selected: selected,
                      onSelected: (_) {
                        _markDirty();
                        final next = [..._genreIds];
                        selected ? next.remove(g.id) : next.add(g.id);
                        field.didChange(next);
                        setState(() => _genreIds = next);
                      },
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}