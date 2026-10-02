import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/validators.dart';
import '../models/publisher.dart';
import '../state/library_provider.dart';

class PublisherFormScreen extends StatefulWidget {
  final int? id;
  const PublisherFormScreen({super.key, this.id});

  bool get isEditing => id != null;

  @override
  State<PublisherFormScreen> createState() => _PublisherFormScreenState();
}

class _PublisherFormScreenState extends State<PublisherFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _cityController = TextEditingController();
  bool _initialized = false;
  bool _isSaving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    if (widget.isEditing) {
      final publisher = context.read<LibraryProvider>().publishers.cast<Publisher?>().firstWhere((p) => p?.id == widget.id, orElse: () => null);
      if (publisher != null) {
        _nameController.text = publisher.name;
        _cityController.text = publisher.city;
      }
    }
    _initialized = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    setState(() => _isSaving = true);
    try {
      final publisher = Publisher(
        id: widget.id ?? 0,
        name: _nameController.text.trim(),
        city: _cityController.text.trim(),
      );
      await context.read<LibraryProvider>().savePublisher(publisher);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? 'Редактировать издательство' : 'Новое издательство')),
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
                decoration: const InputDecoration(labelText: 'Название издательства *', border: OutlineInputBorder()),
                validator: V.combine([V.required(), V.length(min: 2, max: 100)]),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityController,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                decoration: const InputDecoration(labelText: 'Город *', border: OutlineInputBorder()),
                validator: V.combine([V.required(), V.length(min: 2, max: 50)]),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _isSaving ? null : _submit,
                child: Text(widget.isEditing ? 'Сохранить изменения' : 'Создать издательство'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}