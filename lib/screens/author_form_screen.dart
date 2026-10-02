import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/validators.dart';
import '../models/author.dart';
import '../state/library_provider.dart';

class AuthorFormScreen extends StatefulWidget {
  final int? id;
  const AuthorFormScreen({super.key, this.id});

  bool get isEditing => id != null;

  @override
  State<AuthorFormScreen> createState() => _AuthorFormScreenState();
}

class _AuthorFormScreenState extends State<AuthorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  bool _initialized = false;
  bool _isSaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    if (widget.isEditing) {
      final author = context.read<LibraryProvider>().authors.cast<Author?>().firstWhere((a) => a?.id == widget.id, orElse: () => null);
      if (author != null) {
        _nameController.text = author.name;
        _bioController.text = author.biography;
      }
    }
    _initialized = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    setState(() => _isSaving = true);
    try {
      final author = Author(
        id: widget.id ?? 0,
        name: _nameController.text.trim(),
        biography: _bioController.text.trim(),
      );
      await context.read<LibraryProvider>().saveAuthor(author);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? 'Редактировать автора' : 'Новый автор')),
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
                decoration: const InputDecoration(labelText: 'Имя автора *', border: OutlineInputBorder()),
                validator: V.combine([V.required(), V.length(min: 2, max: 100)]),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bioController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Биография', border: OutlineInputBorder()),
                validator: V.length(max: 1000),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _isSaving ? null : _submit,
                child: Text(widget.isEditing ? 'Сохранить изменения' : 'Создать автора'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}