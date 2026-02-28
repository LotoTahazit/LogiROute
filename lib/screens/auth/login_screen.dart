import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/locale_service.dart';
import '../../l10n/app_localizations.dart';
import 'onboarding_screen.dart';

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
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      return;
    }

    setState(() => _isLoading = true);

    final authService = context.read<AuthService>();
    final l10n = AppLocalizations.of(context)!;

    try {
      debugPrint(
          '🔐 LOGIN: start signIn email=${_emailController.text.trim()}');

      final error = await authService
          .signIn(_emailController.text.trim(), _passwordController.text)
          .timeout(const Duration(seconds: 20));

      debugPrint('🔐 LOGIN: signIn finished, error=$error');

      if (!mounted) return;

      if (error != null) {
        String message;
        switch (error) {
          case 'wrong-password':
          case 'user-not-found':
            message = '${l10n.error}: ${l10n.invalidEmail} / ${l10n.password}';
            break;
          case 'invalid-email':
            message = l10n.invalidEmail;
            break;
          case 'api-key-not-valid':
            message = l10n.mapViewRequiresApi;
            break;
          default:
            message = '${l10n.error}: $error';
        }
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } on TimeoutException {
      debugPrint('❌ LOGIN: TIMEOUT (signIn took > 20s)');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: Login timeout (20s)')),
        );
      }
    } catch (e, st) {
      debugPrint('❌ LOGIN: EXCEPTION: $e');
      debugPrint('$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: Text(l10n.appTitle),
        backgroundColor: Colors.blue,
        elevation: 4,
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
                DropdownMenuItem(
                    value: 'he',
                    child: Text('He', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(
                    value: 'ru',
                    child: Text('Ru', style: TextStyle(fontSize: 12))),
                DropdownMenuItem(
                    value: 'en',
                    child: Text('En', style: TextStyle(fontSize: 12))),
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
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.withOpacity(0.1),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 24),
              Image.asset('assets/logo.png', width: 90, height: 90),
              const SizedBox(height: 12),
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'LOGI',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w300,
                        color: Color(0xFF1565C0),
                        letterSpacing: 4,
                      ),
                    ),
                    TextSpan(
                      text: 'ROUTE',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1565C0),
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: l10n.email,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: l10n.password,
                  border: const OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          final email = _emailController.text.trim();
                          if (email.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.email)),
                            );
                            return;
                          }
                          setState(() => _isLoading = true);
                          final authService = context.read<AuthService>();
                          final error =
                              await authService.sendPasswordResetEmail(email);
                          setState(() => _isLoading = false);
                          String message;
                          if (error == null) {
                            message = l10n.passwordResetEmailSent;
                          } else {
                            switch (error) {
                              case 'user-not-found':
                                message = l10n.invalidEmail;
                                break;
                              case 'invalid-email':
                                message = l10n.invalidEmail;
                                break;
                              case 'api-key-not-valid':
                                message = l10n.mapViewRequiresApi;
                                break;
                              default:
                                message = '${l10n.error}: $error';
                            }
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(message)),
                          );
                        },
                  child: Text(l10n.forgotPassword),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
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
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                  );
                },
                child: const Text(
                  'אין לך חשבון? הירשם עכשיו',
                  style: TextStyle(color: Color(0xFF1565C0)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
