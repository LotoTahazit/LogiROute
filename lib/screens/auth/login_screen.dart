import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/locale_service.dart';
import '../../l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) return;

    setState(() => _isLoading = true);
    final authService = context.read<AuthService>();
    final error = await authService.signIn(_emailController.text, _passwordController.text);
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appTitle),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: DropdownButton<String>(
              value: context.watch<LocaleService>().locale.languageCode,
              underline: const SizedBox(),
              icon: const Icon(Icons.language, size: 16),
              items: const [
                DropdownMenuItem(value: 'he', child: Text('He', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: 'ru', child: Text('Ru', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(value: 'en', child: Text('En', style: TextStyle(fontSize: 12))),
              ],
              onChanged: (String? value) {
                if (value != null) {
                  context.read<LocaleService>().setLocale(value);
                }
              },
            ),
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 48),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: l10n.email,
                  labelStyle: const TextStyle(color: Colors.black),
                  border: const OutlineInputBorder(),
                ),
                style: const TextStyle(color: Colors.black),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: l10n.password,
                  labelStyle: const TextStyle(color: Colors.black),
                  border: const OutlineInputBorder(),
                ),
                style: const TextStyle(color: Colors.black),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _signIn,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l10n.login),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

