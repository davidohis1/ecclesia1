import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _loading = false;
  bool _agreeTerms = false;
  final _auth = AuthService();

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeTerms) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please agree to terms'),
          backgroundColor: AppTheme.error));
      return;
    }

    setState(() => _loading = true);
    try {
      final user = await _auth.registerUser(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        username: _usernameCtrl.text.trim(),
        password: _passCtrl.text,
      );
      if (user != null && mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.profileSetup);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.error));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _usernameCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: Stack(
        children: [
          // Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 220,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF3D1FCC), AppTheme.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.arrow_back_rounded,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                          const Spacer(),
                          const EcclesiaLogo(size: 38),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Let's get\nstarted!",
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Form
          Positioned(
            top: 200,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: AppTheme.bgDark,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      EcclesiaTextField(
                        hint: 'John Doe',
                        label: 'Full Name',
                        controller: _nameCtrl,
                        prefix: const Icon(Icons.person_outline,
                            color: AppTheme.textMuted, size: 18),
                        validator: (v) =>
                            v == null || v.length < 2 ? 'Enter your name' : null,
                      ),
                      const SizedBox(height: 16),
                      EcclesiaTextField(
                        hint: 'your@email.com',
                        label: 'Email Address',
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        prefix: const Icon(Icons.email_outlined,
                            color: AppTheme.textMuted, size: 18),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Email required';
                          if (!v.contains('@')) return 'Invalid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      EcclesiaTextField(
                        hint: '@yourusername',
                        label: 'Username',
                        controller: _usernameCtrl,
                        prefix: const Icon(Icons.alternate_email,
                            color: AppTheme.textMuted, size: 18),
                        validator: (v) {
                          if (v == null || v.length < 3) return 'Min 3 chars';
                          if (v.contains(' ')) return 'No spaces allowed';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      EcclesiaTextField(
                        hint: '••••••••',
                        label: 'Password',
                        controller: _passCtrl,
                        obscure: true,
                        prefix: const Icon(Icons.lock_outline,
                            color: AppTheme.textMuted, size: 18),
                        validator: (v) =>
                            v == null || v.length < 6 ? 'Min 6 characters' : null,
                      ),
                      const SizedBox(height: 16),
                      EcclesiaTextField(
                        hint: '••••••••',
                        label: 'Confirm Password',
                        controller: _confirmPassCtrl,
                        obscure: true,
                        prefix: const Icon(Icons.lock_outline,
                            color: AppTheme.textMuted, size: 18),
                        validator: (v) => v != _passCtrl.text
                            ? 'Passwords do not match'
                            : null,
                      ),
                      const SizedBox(height: 20),
                      // Terms checkbox
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _agreeTerms = !_agreeTerms),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: _agreeTerms
                                    ? AppTheme.primary
                                    : AppTheme.bgElevated,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: _agreeTerms
                                        ? AppTheme.primary
                                        : Colors.white.withOpacity(0.2)),
                              ),
                              child: _agreeTerms
                                  ? const Icon(Icons.check,
                                      color: Colors.white, size: 14)
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text.rich(
                              TextSpan(
                                text: 'I agree to the ',
                                style: GoogleFonts.dmSans(
                                    color: AppTheme.textMuted, fontSize: 12),
                                children: [
                                  TextSpan(
                                    text: 'Terms of Service',
                                    style: GoogleFonts.dmSans(
                                        color: AppTheme.primaryLight,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const TextSpan(text: ' and '),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: GoogleFonts.dmSans(
                                        color: AppTheme.primaryLight,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      GradientButton(
                        label: 'Create Account',
                        onTap: _register,
                        loading: _loading,
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: RichText(
                          text: TextSpan(
                            text: 'Already have an account? ',
                            style: GoogleFonts.dmSans(
                                color: AppTheme.textMuted, fontSize: 13),
                            children: [
                              WidgetSpan(
                                child: GestureDetector(
                                  onTap: () => Navigator.pushReplacementNamed(
                                      context, AppRoutes.login),
                                  child: Text(
                                    'Log In',
                                    style: GoogleFonts.dmSans(
                                      color: AppTheme.primaryLight,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
