import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/validation_helper.dart';
import '../../utils/auth_error_messages.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/locale_service.dart';
import '../../services/locale_service_stub.dart'
    if (dart.library.html) '../../services/locale_service_web.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import 'owner_signup_screen.dart';

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
    final saved = loadLoginEmailFromWeb();
    if (saved != null && saved.isNotEmpty) {
      _emailController.text = saved;
    }
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

    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim().toLowerCase();
    if (email.endsWith('.con')) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.emailTypoCon)),
      );
      return;
    }

    final authService = context.read<AuthService>();

    try {
      debugPrint(
          '🔐 LOGIN: start signIn email=${_emailController.text.trim()}');

      final error = await authService
          .signIn(_emailController.text.trim(), _passwordController.text)
          .timeout(const Duration(seconds: 20));

      debugPrint('🔐 LOGIN: signIn finished, error=$error');

      if (!mounted) return;

      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AuthErrorMessages.message(l10n, error)),
          ),
        );
      } else {
        saveLoginEmailToWeb(email);
        TextInput.finishAutofillContext(shouldSave: true);
      }
    } on TimeoutException {
      debugPrint('❌ LOGIN: TIMEOUT (signIn took > 20s)');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: ${l10n.loginTimeout}')),
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
      appBar: AppBar(
        title: Text(l10n.appTitle),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.border),
              borderRadius: BorderRadius.circular(20),
              color: AppTheme.surfaceHi,
            ),
            child: DropdownButton<String>(
              value: context.watch<LocaleService>().locale.languageCode,
              underline: const SizedBox(),
              icon: Icon(Icons.language, size: 16),
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
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 22,
                offset: const Offset(0, 10),
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
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'LOGI',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w300,
                        color: AppTheme.accentSoft,
                        letterSpacing: 4,
                      ),
                    ),
                    TextSpan(
                      text: 'ROUTE',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.accentSoft,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              AutofillGroup(
                child: Column(
                  children: [
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(labelText: l10n.email),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      enableSuggestions: false,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(labelText: l10n.password),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: TextInputAction.done,
                      onSubmitted: _isLoading ? null : (_) => _signIn(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () => Navigator.push<void>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const OwnerSignupScreen(),
                          ),
                        ),
                child: Text(l10n.noAccount),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          final email = _emailController.text.trim().toLowerCase();
                          if (email.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.email)),
                            );
                            return;
                          }
                          if (!ValidationHelper.isValidEmail(email)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.invalidEmail)),
                            );
                            return;
                          }
                          if (email.endsWith('@google.com')) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.emailTypoGmail)),
                            );
                            return;
                          }
                          if (email.endsWith('.con')) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(l10n.emailTypoCon)),
                            );
                            return;
                          }
                          setState(() => _isLoading = true);
                          final authService = context.read<AuthService>();
                          final messenger = ScaffoldMessenger.of(context);
                          final error = await authService.sendPasswordResetEmail(
                            email,
                            languageCode: context
                                .read<LocaleService>()
                                .locale
                                .languageCode,
                          );
                          setState(() => _isLoading = false);
                          final message = error == null
                              ? l10n.passwordResetEmailSent
                              : AuthErrorMessages.message(
                                  l10n,
                                  error,
                                  passwordReset: true,
                                );
                          messenger.showSnackBar(
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
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: TextStyle(fontSize: 16),
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
            ],
          ),
        ),
      ),
    );
  }
}
