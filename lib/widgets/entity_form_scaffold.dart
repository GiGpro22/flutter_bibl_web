import 'package:flutter/material.dart';

class EntityFormScaffold extends StatelessWidget {
  final String title;
  final GlobalKey<FormState> formKey;
  final bool isDirty;
  final bool isSaving;
  final VoidCallback onSave;
  final Widget child;

  const EntityFormScaffold({
    super.key,
    required this.title,
    required this.formKey,
    required this.isDirty,
    required this.isSaving,
    required this.onSave,
    required this.child,
  });

  Future<bool> _showExitDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Несохранённые изменения'),
        content: const Text('Данные формы были изменены. Вы уверены, что хотите уйти без сохранения?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Остаться'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Покинуть'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _showExitDialog(context);
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    child,
                    const SizedBox(height: 32),
                    FilledButton(
                      onPressed: isSaving ? null : onSave,
                      child: isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Сохранить'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}