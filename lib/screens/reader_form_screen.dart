import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/validators.dart';
import '../models/reader.dart';
import '../state/library_provider.dart';

class ReaderFormScreen extends StatefulWidget {
  final int? id;
  const ReaderFormScreen({super.key, this.id});

  bool get isEditing => id != null;

  @override
  State<ReaderFormScreen> createState() => _ReaderFormScreenState();
}

class _ReaderFormScreenState extends State<ReaderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _initialized = false;
  bool _isSaving = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  // Вложенная группа полей для Читательского билета (1:1)
  final _cardNumberController = TextEditingController();
  String _cardStatus = 'Активен';
  DateTime _cardIssueDate = DateTime.now();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;

    if (widget.isEditing) {
      final provider = context.read<LibraryProvider>();
      final reader = provider.readers.cast<Reader?>().firstWhere((r) => r?.id == widget.id, orElse: () => null);
      if (reader != null) {
        _nameController.text = reader.fullName;
        _emailController.text = reader.email;
        _phoneController.text = reader.phone;
        _cardNumberController.text = reader.card.cardNumber;
        _cardStatus = reader.card.status;
        _cardIssueDate = reader.card.issueDate;
      }
    } else {
      _cardNumberController.text = 'CARD-${DateTime.now().millisecondsSinceEpoch % 10000}';
    }
    _initialized = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cardNumberController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    setState(() => _isSaving = true);
    try {
      final provider = context.read<LibraryProvider>();
      final reader = Reader(
        id: widget.id ?? 0,
        fullName: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        card: LibraryCard(
          cardNumber: _cardNumberController.text.trim(),
          issueDate: _cardIssueDate,
          status: _cardStatus,
        ),
      );

      await provider.saveReader(reader);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(widget.isEditing ? 'Читатель обновлен' : 'Читатель зарегистрирован')),
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

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Редактировать читателя' : 'Новый читатель'),
      ),
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
                decoration: const InputDecoration(labelText: 'ФИО читателя *', border: OutlineInputBorder()),
                validator: V.combine([V.required(), V.length(min: 3, max: 120)]),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Email *', border: OutlineInputBorder()),
                validator: (val) {
                  final err = V.combine([V.required(), V.email()])(val);
                  if (err != null) return err;
                  if (!provider.isReaderEmailFree(val!, exceptId: widget.id)) {
                    return 'Читатель с таким email уже зарегистрирован';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Номер телефона', border: OutlineInputBorder()),
                validator: V.length(max: 20),
              ),
              const SizedBox(height: 24),
              // Вложенный блок сущности 1:1 - Читательский билет
              Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: Colors.grey.shade300)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Читательский билет (Связь 1:1)', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _cardNumberController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: 'Номер билета *', border: OutlineInputBorder()),
                        validator: V.combine([V.required(), V.length(min: 3, max: 50)]),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _cardStatus,
                        decoration: const InputDecoration(labelText: 'Статус билета', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'Активен', child: Text('Активен')),
                          DropdownMenuItem(value: 'Заблокирован', child: Text('Заблокирован')),
                          DropdownMenuItem(value: 'Приостановлен', child: Text('Приостановлен')),
                        ],
                        onChanged: (val) => setState(() => _cardStatus = val ?? 'Активен'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _isSaving ? null : _submit,
                child: _isSaving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(widget.isEditing ? 'Сохранить изменения' : 'Зарегистрировать читателя'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
