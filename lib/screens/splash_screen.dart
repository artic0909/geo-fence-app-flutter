import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bgAnimation;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<Offset> _textSlide;
  late Animation<double> _glassOpacity;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );

    _bgAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
    );

    _logoScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.6, curve: Curves.elasticOut),
      ),
    );

    _logoOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.4, curve: Curves.easeIn),
      ),
    );

    _glassOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.8, curve: Curves.easeIn),
      ),
    );

    _textSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 0.9, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 4));

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null) {
      _fadeAndNavigate(const HomeScreen());
    } else {
      _fadeAndNavigate(const LoginScreen());
    }
  }

  void _fadeAndNavigate(Widget screen) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 1000),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color saffron = Color(0xFFFF9933);
    const Color green = Color(0xFF138808);

    return Scaffold(
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  saffron,
                  Colors.white,
                  green,
                ],
                stops: [
                  0.0,
                  0.5 * _bgAnimation.value,
                  1.0,
                ],
              ),
            ),
            child: Stack(
              children: [
                // 1. Map Background with Radar Animation
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.15,
                    child: Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Image.asset(
                            'assets/map.png',
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                          const RadarAnimation(),
                        ],
                      ),
                    ),
                  ),
                ),

                // Background Animated Shapes
                Positioned(
                  top: 100 * (1 - _bgAnimation.value),
                  left: -50,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 100 * (1 - _bgAnimation.value),
                  right: -50,
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),

                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Glassmorphic Card
                      FadeTransition(
                        opacity: _glassOpacity,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                            child: Container(
                              padding: const EdgeInsets.all(40),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(50),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.5),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 30,
                                    spreadRadius: -10,
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // Animated Logo
                                  FadeTransition(
                                    opacity: _logoOpacity,
                                    child: ScaleTransition(
                                      scale: _logoScale,
                                      child: Hero(
                                        tag: 'app_logo',
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(25),
                                          child: Image.asset(
                                            'assets/playstore.png',
                                            width: 120,
                                            height: 120,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 30),
                                  // Staggered Text
                                  SlideTransition(
                                    position: _textSlide,
                                    child: const Text(
                                      'GEOFENCE',
                                      style: TextStyle(
                                        color: Color(0xFF1A1A1A),
                                        fontSize: 40,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 4,
                                        height: 1,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Tagline
                      FadeTransition(
                        opacity: _glassOpacity,
                        child: const Text(
                          'SMART ATTENDANCE TRACKING',
                          style: TextStyle(
                            color: Color(0xFF2E2E2E),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Loader
                Positioned(
                  bottom: 70,
                  left: 0,
                  right: 0,
                  child: FadeTransition(
                    opacity: _glassOpacity,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const LoadingDots(),
                          const SizedBox(height: 20),
                          Text(
                            'PRECISE • SECURE • RELIABLE',
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.5),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2,
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
        },
      ),
    );
  }
}

class LoadingDots extends StatefulWidget {
  const LoadingDots({super.key});

  @override
  State<LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<LoadingDots> with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color saffron = Color(0xFFFF9933);
    const Color green = Color(0xFF138808);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            // Calculate progress for each dot with an offset
            double progress = (_controller.value + (index * 0.2)) % 1.0;
            
            // Transform opacity and scale based on progress
            double opacity = 0.3 + (0.7 * (1.0 - (progress - 0.5).abs() * 2));
            double scale = 0.8 + (0.4 * (1.0 - (progress - 0.5).abs() * 2));
            
            Color color = index == 0 ? saffron : (index == 1 ? Colors.white : green);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Opacity(
                opacity: opacity.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: scale.clamp(0.0, 1.5),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class RadarAnimation extends StatefulWidget {
  const RadarAnimation({super.key});

  @override
  State<RadarAnimation> createState() => _RadarAnimationState();
}

class _RadarAnimationState extends State<RadarAnimation> with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: List.generate(3, (index) {
            double value = (_controller.value + (index / 3)) % 1.0;
            return Container(
              width: MediaQuery.of(context).size.width * 1.5 * value,
              height: MediaQuery.of(context).size.width * 1.5 * value,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity((1 - value) * 0.4),
                  width: 1.5,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

