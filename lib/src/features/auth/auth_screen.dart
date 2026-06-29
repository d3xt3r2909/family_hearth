import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/auth_repository.dart';
import '../../i18n/app_localizations.dart';
import '../shared/family_hearth_mark.dart';
import '../shared/language_menu.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.authRepository});

  final AuthRepository authRepository;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _creatingAccount = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) {
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      if (_creatingAccount) {
        await widget.authRepository.createAccount(
          email: _emailController.text,
          password: _passwordController.text,
          displayName: _nameController.text,
        );
      } else {
        await widget.authRepository.signIn(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }
    } on FirebaseAuthException catch (error) {
      setState(() => _error = _friendlyAuthError(error));
    } on Object catch (error) {
      setState(() => _error = context.t.couldNotSignIn('$error'));
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = context.t;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF7EC), Color(0xFFFFE2BF), Color(0xFFDDF2E8)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              const Positioned(top: 14, right: 18, child: LanguageMenu()),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(22),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Material(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: Color(0xFFE7D9CC)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Center(
                              child: FamilyHearthMark(
                                size: 96,
                                backgroundColor: Color(0xFFFFC56B),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              _creatingAccount
                                  ? strings.createYourFamilyHearth
                                  : strings.welcomeBack,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF221B16),
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _creatingAccount
                                  ? strings.createAccountSubtitle
                                  : strings.signInSubtitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF6F6258),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 22),
                            if (_creatingAccount) ...[
                              TextField(
                                controller: _nameController,
                                textInputAction: TextInputAction.next,
                                decoration: _fieldDecoration(
                                  icon: Icons.badge_rounded,
                                  label: strings.yourName,
                                ),
                              ),
                              const SizedBox(height: 12),
                            ],
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autocorrect: false,
                              decoration: _fieldDecoration(
                                icon: Icons.email_rounded,
                                label: strings.email,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _passwordController,
                              obscureText: true,
                              onSubmitted: (_) => _submit(),
                              decoration: _fieldDecoration(
                                icon: Icons.lock_rounded,
                                label: strings.password,
                              ),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 14),
                              _ErrorBox(message: _error!),
                            ],
                            const SizedBox(height: 18),
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(52),
                                backgroundColor: const Color(0xFFE85D43),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: _busy ? null : _submit,
                              icon: _busy
                                  ? const SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Icon(
                                      _creatingAccount
                                          ? Icons.favorite_rounded
                                          : Icons.login_rounded,
                                    ),
                              label: Text(
                                _creatingAccount
                                    ? strings.createAccount
                                    : strings.signIn,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _busy
                                  ? null
                                  : () => setState(
                                      () =>
                                          _creatingAccount = !_creatingAccount,
                                    ),
                              child: Text(
                                _creatingAccount
                                    ? strings.alreadyHaveAccount
                                    : strings.createNewAccount,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required IconData icon,
    required String label,
  }) {
    return InputDecoration(
      prefixIcon: Icon(icon),
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFFFFBF7),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE7D9CC)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE85D43), width: 2),
      ),
    );
  }

  String _friendlyAuthError(FirebaseAuthException error) {
    final strings = context.t;

    return switch (error.code) {
      'email-already-in-use' => strings.emailAlreadyInUse,
      'invalid-email' => strings.invalidEmail,
      'weak-password' => strings.weakPassword,
      'user-not-found' ||
      'wrong-password' ||
      'invalid-credential' => strings.wrongCredentials,
      'operation-not-allowed' => strings.emailPasswordNotEnabled,
      _ => strings.couldNotSignInCode(error.code),
    };
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECE8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFB8A8)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_rounded, color: Color(0xFFE02F2F)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF7B241C),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
