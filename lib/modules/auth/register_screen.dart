import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_theme.dart';
import '../../core/exceptions/app_exception.dart';
import '../../core/session/session_manager.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../user/welcome_screen.dart';
import 'login_screen.dart';

const _kPhonePrefix = '+91';
const _kDefaultRole = 'user';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey            = GlobalKey<FormState>();
  final _nameController     = TextEditingController();
  final _emailController    = TextEditingController();
  final _phoneController    = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading       = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);

    try {
      final name     = _nameController.text.trim();
      final email    = _emailController.text.trim();
      final phone    = _phoneController.text.trim();
      final password = _passwordController.text;

      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final user = credential.user!;
      await user.updateDisplayName(name);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'userId'   : user.uid,
        'name'     : name,
        'email'    : email,
        'phone'    : '$_kPhonePrefix$phone',
        'role'     : _kDefaultRole,
        'isActive' : true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await SessionManager.instance.loadSession(user.uid);

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: const Text('Account created successfully!'),
          backgroundColor: AppTheme.green,
          behavior: SnackBarBehavior.floating,
        ));

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(builder: (_) => const WelcomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      _showError(_mapAuthError(e));
    } on AppException catch (e) {
      _showError(e.message);
    } catch (_) {
      _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':   return 'This email is already registered. Try logging in.';
      case 'invalid-email':          return 'Enter a valid email address.';
      case 'weak-password':          return 'Password is too weak. Use at least 6 characters.';
      case 'network-request-failed': return 'No internet connection. Check your network.';
      default:                       return 'Registration failed. Please try again.';
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.red,
        behavior: SnackBarBehavior.floating,
      ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Register'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppTheme.border),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 32),
                  _buildNameField(),
                  const SizedBox(height: 16),
                  _buildEmailField(),
                  const SizedBox(height: 16),
                  _buildPhoneField(),
                  const SizedBox(height: 16),
                  _buildPasswordField(),
                  const SizedBox(height: 28),
                  _buildRegisterButton(),
                  const SizedBox(height: 16),
                  _buildLoginLink(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      children: [
        Icon(Icons.person_add_rounded, size: 64, color: AppTheme.accent),
        SizedBox(height: 12),
        Text(
          'Create Account',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Register to get started',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildNameField() {
    return CustomTextField(
      controller: _nameController,
      hintText: 'Full Name',
      prefixIcon: Icons.person_outline,
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.words,
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Full name is required.';
        if (v.trim().length < 2) return 'Enter a valid name.';
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return CustomTextField(
      controller: _emailController,
      hintText: 'Email',
      prefixIcon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Email is required.';
        if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w{2,}$').hasMatch(v.trim()))
          return 'Enter a valid email.';
        return null;
      },
    );
  }

  Widget _buildPhoneField() {
    return CustomTextField(
      controller: _phoneController,
      hintText: 'Phone Number (10 digits)',
      prefixIcon: Icons.phone_outlined,
      prefixText: '$_kPhonePrefix ',
      keyboardType: TextInputType.phone,
      textInputAction: TextInputAction.next,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      validator: (v) {
        if (v == null || v.trim().isEmpty) return 'Phone number is required.';
        if (v.trim().length != 10) return 'Enter a valid 10-digit number.';
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return CustomTextField(
      controller: _passwordController,
      hintText: 'Password',
      prefixIcon: Icons.lock_outline,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _register(),
      suffixIcon: IconButton(
        icon: Icon(
          _obscurePassword
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: AppTheme.textSecondary,
        ),
        onPressed: () =>
            setState(() => _obscurePassword = !_obscurePassword),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Password is required.';
        if (v.length < 6) return 'Password must be at least 6 characters.';
        return null;
      },
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      height: 50,
      child: CustomButton(
        text: 'Register',
        isLoading: _isLoading,
        onPressed: _isLoading ? null : _register,
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Already have an account? ',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
                builder: (_) => const LoginScreen()),
          ),
          child: const Text(
            'Login',
            style: TextStyle(
              color: AppTheme.accent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}