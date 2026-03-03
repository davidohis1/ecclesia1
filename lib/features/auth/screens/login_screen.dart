import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  final _auth = AuthService();

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final user = await _auth.loginUser(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      if (user != null && mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: MediaQuery.of(context).size.height * 0.42,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary, AppTheme.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  // Pattern
                  Positioned.fill(child: _AuthPatternPainter()),
                  SafeArea(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const EcclesiaLogo(size: 68),
                          const SizedBox(height: 16),
                          Text(
                            'Ecclesia',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Welcome back, Saint',
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              color: Colors.white70,
                              letterSpacing: 0.5,
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
          // Bottom form card
          Positioned(
            top: MediaQuery.of(context).size.height * 0.36,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: AppTheme.bgDark,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Sign In',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Continue your faith journey',
                        style: GoogleFonts.dmSans(
                          color: AppTheme.textMuted,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 28),
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
                        hint: '••••••••',
                        label: 'Password',
                        controller: _passCtrl,
                        obscure: true,
                        prefix: const Icon(Icons.lock_outline,
                            color: AppTheme.textMuted, size: 18),
                        validator: (v) {
                          if (v == null || v.length < 6)
                            return 'Min 6 characters';
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => _showForgotPassword(),
                          child: Text(
                            'Forgot Password?',
                            style: GoogleFonts.dmSans(
                              color: AppTheme.primaryLight,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      GradientButton(
                        label: 'Log In',
                        onTap: _login,
                        loading: _loading,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                              child: Divider(color: Colors.white.withOpacity(0.1))),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'Or',
                              style: GoogleFonts.dmSans(
                                  color: AppTheme.textMuted, fontSize: 13),
                            ),
                          ),
                          Expanded(
                              child: Divider(color: Colors.white.withOpacity(0.1))),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _SocialLoginRow(),
                      const SizedBox(height: 32),
                      Center(
                        child: RichText(
                          text: TextSpan(
                            text: "Don't have an account? ",
                            style: GoogleFonts.dmSans(
                                color: AppTheme.textMuted, fontSize: 13),
                            children: [
                              WidgetSpan(
                                child: GestureDetector(
                                  onTap: () => Navigator.pushReplacementNamed(
                                      context, AppRoutes.onboarding),
                                  child: Text(
                                    'Sign Up',
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

  void _showForgotPassword() {
    final emailCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reset Password',
                style: GoogleFonts.playfairDisplay(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Text('Enter your email to receive a reset link',
                style: GoogleFonts.dmSans(
                    color: AppTheme.textMuted, fontSize: 13)),
            const SizedBox(height: 20),
            EcclesiaTextField(
                hint: 'your@email.com', controller: emailCtrl),
            const SizedBox(height: 20),
            GradientButton(
              label: 'Send Reset Link',
              onTap: () async {
                if (emailCtrl.text.isNotEmpty) {
                  await _auth.sendPasswordReset(emailCtrl.text.trim());
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Reset link sent!')));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthPatternPainter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _AuthBgPainter());
  }
}

class _AuthBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (int i = 1; i <= 6; i++) {
      canvas.drawCircle(
          Offset(size.width * 0.9, size.height * 0.1), i * 55.0, paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _SocialLoginRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _SocialBtn(icon: '🇬', label: 'Google'),
        const SizedBox(width: 16),
        _SocialBtn(icon: '🍎', label: 'Apple'),
        const SizedBox(width: 16),
        _SocialBtn(icon: '🔵', label: 'Facebook'),
      ],
    );
  }
}

class _SocialBtn extends StatelessWidget {
  final String icon;
  final String label;
  const _SocialBtn({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 48,
      decoration: BoxDecoration(
        color: AppTheme.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Center(child: Text(icon, style: const TextStyle(fontSize: 22))),
    );
  }
}
