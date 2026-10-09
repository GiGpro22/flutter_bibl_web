import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../core/api_exceptions.dart';
import '../state/auth_notifier.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _hasMinLen = false;
  bool _hasDigit = false;
  bool _hasSpecial = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePasswordLive);
  }

  void _validatePasswordLive() {
    final text = _passwordController.text;
    setState(() {
      _hasMinLen = text.length >= 8;
      _hasDigit = RegExp(r'[0-9]').hasMatch(text);
      _hasSpecial = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(text);
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_hasMinLen || !_hasDigit || !_hasSpecial) return;
    if (!_formKey.currentState!.validate() || _isLoading) return;

    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await context.read<AuthNotifier>().register(
        _emailController.text,
        _passwordController.text,
        _nameController.text,
      );
      if (mounted) context.go('/');
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Регистрация читателя')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Новый читатель', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(10),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(8)),
                        child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade900)),
                      ),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Полное имя', border: OutlineInputBorder()),
                      validator: (val) => val == null || val.isEmpty ? 'Введите имя' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                      validator: (val) => val == null || !val.contains('@') ? 'Корректный email' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      decoration: const InputDecoration(labelText: 'Пароль', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 12),
                    // Живой индикатор сложности пароля
                    _buildCheckRow('Не менее 8 символов', _hasMinLen),
                    _buildCheckRow('Содержит цифру', _hasDigit),
                    _buildCheckRow(r'Содержит спецсимвол (!@#$...)', _hasSpecial),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: (_hasMinLen && _hasDigit && _hasSpecial && !_isLoading) ? _submit : null,
                      child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Зарегистрироваться'),
                    ),
                    TextButton(onPressed: () => context.go('/login'), child: const Text('Уже есть аккаунт? Войти')),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckRow(String label, bool passed) {
    return Row(
      children: [
        Icon(passed ? Icons.check_circle : Icons.circle_outlined, size: 16, color: passed ? Colors.green : Colors.grey),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 12, color: passed ? Colors.green.shade800 : Colors.grey.shade700)),
      ],
    );
  }
}
