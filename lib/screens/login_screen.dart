import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/brand.dart';
import '../widgets/form_widgets.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String _errorText(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Incorrect email or password.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'network-request-failed':
        return 'No internet connection. Please try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
      // On success the app switches to Home automatically.
    } on FirebaseAuthException catch (e) {
      if (mounted) showMessage(context, _errorText(e), error: true);
    } catch (_) {
      if (mounted) {
        showMessage(context, 'Something went wrong. Please try again.', error: true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _email.text.trim();
    if (!email.contains('@')) {
      showMessage(context, 'Type your email above first, then tap Forgot password.',
          error: true);
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        showMessage(context, 'If an account exists, a reset link was sent to $email.');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) showMessage(context, _errorText(e), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: BrandHeader()),
            const SizedBox(height: 32),
            const Text('Welcome back',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const SizedBox(height: 6),
            const Text('Sign in to continue your scholarship journey.',
                style: TextStyle(fontSize: 14, color: AppColors.muted)),
            const SizedBox(height: 28),
            AppTextField(
              label: 'Email address',
              hint: 'student@example.com',
              controller: _email,
              icon: Icons.person_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Password',
              hint: 'At least 8 characters',
              controller: _password,
              icon: Icons.verified_user_outlined,
              obscure: true,
              textInputAction: TextInputAction.done,
              validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _forgotPassword,
                child: const Text('Forgot password?',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.forest)),
              ),
            ),
            const SizedBox(height: 4),
            PrimaryButton(label: 'Sign in', loading: _loading, onPressed: _submit),
            const SizedBox(height: 22),
            const Row(
              children: [
                Expanded(child: Divider(color: AppColors.border)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('or continue with',
                      style: TextStyle(fontSize: 12, color: AppColors.muted)),
                ),
                Expanded(child: Divider(color: AppColors.border)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 54,
              child: OutlinedButton.icon(
                onPressed: () => showMessage(context, 'Google sign-in is coming soon.'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ink,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
                icon: const Icon(Icons.g_mobiledata_rounded, size: 32),
                label: const Text('Continue with Google'),
              ),
            ),
            const SizedBox(height: 28),
            Center(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('New to ScholarKhoj? ',
                      style: TextStyle(fontSize: 13, color: AppColors.muted)),
                  InkWell(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RegisterScreen()),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Text('Create account',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.forest)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}