import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/constants/app_constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<OnboardSlide> _slides = [
    OnboardSlide(
      emoji: '✝️',
      title: 'Welcome to\nEcclesia',
      subtitle: 'The sacred space where believers connect, grow, and worship together in the digital age.',
      gradientColors: [const Color(0xFF6B4EFF), const Color(0xFF3D1FCC)],
      accentColor: AppTheme.accent,
    ),
    OnboardSlide(
      emoji: '🙏',
      title: 'Share Your\nFaith Journey',
      subtitle: 'Post testimonies, scriptures, and devotionals. Let your light shine to fellow saints worldwide.',
      gradientColors: [const Color(0xFF1A1A2E), const Color(0xFF16213E)],
      accentColor: const Color(0xFFFFD700),
    ),
    OnboardSlide(
      emoji: '🎵',
      title: 'Worship\nWithout Borders',
      subtitle: 'Stream and download gospel music, hymns, and worship songs. Praise from wherever you are.',
      gradientColors: [const Color(0xFF0F3460), const Color(0xFF533483)],
      accentColor: const Color(0xFF00D4AA),
    ),
    OnboardSlide(
      emoji: '📖',
      title: 'Grow in\nThe Word',
      subtitle: 'Access a library of Christian books, devotionals, and theological resources in one place.',
      gradientColors: [const Color(0xFF1B4332), const Color(0xFF2D6A4F)],
      accentColor: const Color(0xFFA8E063),
    ),
    OnboardSlide(
      emoji: '🕊️',
      title: 'Discuss &\nDisciple',
      subtitle: 'Join Spirit-led discussions, prayer rooms, and faith conversations. Build the Kingdom together.',
      gradientColors: [const Color(0xFF6B4EFF), const Color(0xFF00D4AA)],
      accentColor: Colors.white,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _slides.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.register);
    }
  }

  void _skip() {
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: _slides.length,
            itemBuilder: (_, i) => _OnboardPage(slide: _slides[i]),
          ),
          // Top skip button
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: TextButton(
                  onPressed: _skip,
                  child: Text(
                    'Skip',
                    style: GoogleFonts.dmSans(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 36),
                child: Column(
                  children: [
                    SmoothPageIndicator(
                      controller: _controller,
                      count: _slides.length,
                      effect: ExpandingDotsEffect(
                        dotColor: Colors.white30,
                        activeDotColor: _slides[_currentPage].accentColor,
                        dotHeight: 6,
                        dotWidth: 6,
                        expansionFactor: 4,
                      ),
                    ),
                    const SizedBox(height: 32),
                    GradientButton(
                      label: _currentPage == _slides.length - 1
                          ? 'Get Started'
                          : 'Continue',
                      onTap: _next,
                      colors: [
                        _slides[_currentPage].accentColor,
                        _slides[_currentPage].accentColor.withOpacity(0.7),
                      ],
                      icon: _currentPage == _slides.length - 1
                          ? const Icon(Icons.arrow_forward_rounded,
                              color: Colors.black, size: 18)
                          : null,
                    ),
                    const SizedBox(height: 16),
                    if (_currentPage < _slides.length - 1)
                      TextButton(
                        onPressed: _skip,
                        child: Text(
                          'Already have an account? Log In',
                          style: GoogleFonts.dmSans(
                            color: Colors.white60,
                            fontSize: 13,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardPage extends StatelessWidget {
  final OnboardSlide slide;
  const _OnboardPage({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: slide.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: CustomPaint(painter: _CirclePatternPainter(slide.accentColor)),
          ),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const SizedBox(height: 80),
                  // Big emoji in glowing circle
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.08),
                      border: Border.all(
                        color: slide.accentColor.withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: slide.accentColor.withOpacity(0.15),
                          blurRadius: 60,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(slide.emoji, style: const TextStyle(fontSize: 72)),
                    ),
                  ),
                  const SizedBox(height: 56),
                  Text(
                    slide.title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    slide.subtitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      color: Colors.white70,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CirclePatternPainter extends CustomPainter {
  final Color color;
  _CirclePatternPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 1; i <= 5; i++) {
      canvas.drawCircle(
        Offset(size.width * 0.85, size.height * 0.15),
        i * 60.0,
        paint,
      );
    }
    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(
        Offset(size.width * 0.1, size.height * 0.75),
        i * 50.0,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class OnboardSlide {
  final String emoji;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final Color accentColor;

  const OnboardSlide({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.accentColor,
  });
}
