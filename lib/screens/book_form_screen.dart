import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_exceptions.dart';
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

  Map<String, String> _serverErrors = {};

  final _titleController = TextEditingController();
  final _isbnController = TextEditingController();
  final _yearController = TextEditingController();
  final _pagesController = TextEditingController();
  final _copiesTotalController = TextEditingController();

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
      final book = context.read<LibraryProvider>().books.cast<Book?>().firstWhere(
        (b) => b?.id == widget.id, orElse: () => null,
      );
      if (book != null) {
        _titleController.text = book.title;
        _isbnController.text = book.isbn;
        _yearController.text = book.year == 0 ? '' : book.year.toString();
        _pagesController.text = book.pages == 0 ? '' : book.pages.toString();
        _copiesTotalController.text = book.copiesTotal.toString();
        _publisherId = book.publisherId == 0 ? null : book.publisherId;
        _authorIds = [...book.authorIds];
        _genreIds = [...book.genreIds];
      }
    }

    _titleController.addListener(_markDirty);
    _isbnController.addListener(() {
      _markDirty();
      if (_serverErrors.containsKey('isbn')) {
        setState(() => _serverErrors.remove('isbn'));
      }
    });
    _yearController.addListener(_markDirty);
    _pagesController.addListener(_markDirty);
    _copiesTotalController.addListener(_markDirty);

    _initialized = true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _isbnController.dispose();
    _yearController.dispose();
    _pagesController.dispose();
    _copiesTotalController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _serverErrors = {});
    if (!_formKey.currentState!.validate() || _isSaving) return;

    setState(() => _isSaving = true);
    try {
      final book = Book(
        id: widget.id ?? 0,
        title: _titleController.text.trim(),
        isbn: _isbnController.text.trim(),
        year: int.tryParse(_yearController.text.trim()) ?? 0,
        pages: int.tryParse(_pagesController.text.trim()) ?? 0,
        copiesTotal: int.tryParse(_copiesTotalController.text.trim()) ?? 1,
        publisherId: _publisherId ?? 0,
        authorIds: _authorIds,
        genreIds: _genreIds,
      );

      await context.read<LibraryProvider>().saveBook(book);
      _isDirty = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.isEditing ? 'Книга обновлена на сервере' : 'Книга создана на сервере')),
        );
        Navigator.of(context).pop();
      }
    } on ValidationException catch (e) {
      setState(() => _serverErrors = e.errors);
      _formKey.currentState!.validate();
    } on ConflictException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red.shade700, content: Text(e.message)),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.red, content: Text(e.message)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LibraryProvider>();
    final publishers = provider.publishers;
    final authors = provider.authors;

    Publisher? selectedPub;
    if (_publisherId != null) {
      selectedPub = publishers.cast<Publisher?>().firstWhere((p) => p?.id == _publisherId, orElse: () => null);
    }

    final availableGenres = selectedPub == null
        ? provider.genres
        : provider.genres.where((g) => selectedPub!.supportedGenreIds.contains(g.id)).toList();

    return EntityFormScaffold(
      title: widget.isEditing ? 'Редактировать книгу' : 'Новая книга (REST API)',
      formKey: _formKey,
      isDirty: _isDirty,
      isSaving: _isSaving,
      onSave: _submit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Название книги *',
              border: const OutlineInputBorder(),
              errorText: _serverErrors['title'],
            ),
            validator: V.combine([V.required(), V.length(min: 2, max: 200)]),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _isbnController,
            decoration: InputDecoration(
              labelText: 'ISBN *',
              border: const OutlineInputBorder(),
              helperText: 'Проверка уникальности на сервере (код 422)',
              errorText: _serverErrors['isbn'],
            ),
            validator: (val) {
              final req = V.required()(val);
              if (req != null) return req;
              return _serverErrors['isbn'];
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _yearController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Год издания', border: OutlineInputBorder()),
                  validator: V.integer(min: 1450, max: DateTime.now().year + 1),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _pagesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Страниц', border: OutlineInputBorder()),
                  validator: V.integer(min: 1, max: 10000),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _copiesTotalController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Всего экземпляров *', border: OutlineInputBorder()),
            validator: V.combine([V.required(), V.integer(min: 0)]),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<int>(
            value: publishers.any((p) => p.id == _publisherId) ? _publisherId : null,
            decoration: const InputDecoration(labelText: 'Издательство (справочник) *', border: OutlineInputBorder()),
            items: publishers.map((p) => DropdownMenuItem(value: p.id, child: Text('${p.name} (${p.city})'))).toList(),
            onChanged: (val) {
              _markDirty();
              setState(() => _publisherId = val);
            },
            validator: (val) => val == null ? 'Выберите издательство' : null,
          ),
          const SizedBox(height: 20),
          FormField<List<int>>(
            initialValue: _authorIds,
            validator: (val) => (val == null || val.isEmpty) ? 'Выберите хотя бы одного автора' : null,
            builder: (field) {
              return InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Авторы (справочник) *',
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
          FormField<List<int>>(
            initialValue: _genreIds,
            validator: (val) => (val == null || val.isEmpty) ? 'Выберите жанр' : null,
            builder: (field) {
              return InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Жанры (каскадно фильтруются) *',
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