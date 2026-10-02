import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/validators.dart';
import '../models/genre.dart';
import '../state/library_provider.dart';

class GenreFormScreen extends StatefulWidget {
  final int? id;
  const GenreFormScreen({super.key, this.id});

  bool get isEditing => id != null;

  @override
  State<GenreFormScreen> createState() => _GenreFormScreenState();
}

class _GenreFormScreenState extends State<GenreFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  bool _initialized = false;
  bool _isSaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    if (widget.isEditing) {
      final genre = context.read<LibraryProvider>().genres.cast<Genre?>().firstWhere((g) => g?.id == widget.id, orElse: () => null);
      if (genre != null) {
        _nameController.text = genre.name;
        _descController.text = genre.description;
      }
    }
    _initialized = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    setState(() => _isSaving = true);
    try {
      final genre = Genre(
        id: widget.id ?? 0,
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
      );
      await context.read<LibraryProvider>().saveGenre(genre);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? 'Редактировать жанр' : 'Новый жанр')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Название жанра *', border: OutlineInputBorder()),
                validator: V.combine([V.required(), V.length(min: 2, max: 50)]),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Описание', border: OutlineInputBorder()),
                validator: V.length(max: 300),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _isSaving ? null : _submit,
                child: Text(widget.isEditing ? 'Сохранить изменения' : 'Создать жанр'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}