import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/brand.dart';
import '../widgets/form_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String _errorText(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'An account with this email already exists.';
      case 'weak-password':
        return 'Password is too weak. Use at least 8 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'network-request-failed':
        return 'No internet connection. Please try again.';
      default:
        return e.message ?? 'Something went wrong. Please try again.';
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
      await cred.user!.updateDisplayName(_name.text.trim());
      await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
        'name': _name.text.trim(),
        'email': _email.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      // The app now shows Home underneath; close this screen to reveal it.
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
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

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: BrandHeader()),
            const SizedBox(height: 28),
            const Text('Create your account',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const SizedBox(height: 6),
            const Text('Start discovering opportunities made for you.',
                style: TextStyle(fontSize: 14, color: AppColors.muted)),
            const SizedBox(height: 24),
            AppTextField(
              label: 'Full name',
              hint: 'Enter your full name',
              controller: _name,
              icon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Email address',
              hint: 'student@example.com',
              controller: _email,
              icon: Icons.person_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Password',
              hint: 'At least 8 characters',
              controller: _password,
              icon: Icons.verified_user_outlined,
              obscure: true,
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || v.length < 8) ? 'Use at least 8 characters' : null,
            ),
            const SizedBox(height: 14),
            AppTextField(
              label: 'Confirm password',
              hint: 'Re-enter your password',
              controller: _confirm,
              icon: Icons.verified_user_outlined,
              obscure: true,
              textInputAction: TextInputAction.done,
              validator: (v) => v != _password.text ? 'Passwords do not match' : null,
            ),
            const SizedBox(height: 24),
            PrimaryButton(label: 'Create account', loading: _loading, onPressed: _submit),
            const SizedBox(height: 24),
            Center(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('Already have an account? ',
                      style: TextStyle(fontSize: 13, color: AppColors.muted)),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 6),
                      child: Text('Sign in',
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