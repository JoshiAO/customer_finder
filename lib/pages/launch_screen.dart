import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_private_config.dart';
import '../services/app_customization_notifier.dart';

class LaunchScreen extends StatefulWidget {
  const LaunchScreen({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen> with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _textController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);

    _logoScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
    );

    _logoController.forward();

    _timer = Timer(const Duration(milliseconds: 2800), () {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customization = context.watch<AppCustomizationNotifier>();
    final launchTitle = customization.launchTitle;
    final launchLogoProvider = customization.launchLogoImageProvider;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final gradientTop = Color.alphaBlend(
      scheme.primary.withValues(alpha: isDark ? 0.20 : 0.12),
      scheme.surface,
    );
    final gradientMid = Color.alphaBlend(
      scheme.secondary.withValues(alpha: isDark ? 0.22 : 0.14),
      scheme.surface,
    );
    final gradientBottom = Color.alphaBlend(
      scheme.tertiary.withValues(alpha: isDark ? 0.18 : 0.10),
      scheme.surface,
    );

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              gradientTop,
              gradientMid,
              gradientBottom,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ScaleTransition(
                  scale: _logoScale,
                  child: FadeTransition(
                    opacity: _logoFade,
                    child: Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 22,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(28),
                        child: launchLogoProvider != null
                            ? Image(
                                image: launchLogoProvider,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _fallbackLaunchLogo(launchTitle);
                                },
                              )
                            : Image.asset(
                                AppPrivateConfig.launchLogoAsset,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _fallbackLaunchLogo(launchTitle);
                                },
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                AnimatedBuilder(
                  animation: _textController,
                  builder: (context, child) {
                    final glow = 3 + (7 * _textController.value);
                    return ShaderMask(
                      shaderCallback: (bounds) {
                        return LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            scheme.primary,
                            scheme.tertiary,
                            scheme.secondary,
                          ],
                        ).createShader(bounds);
                      },
                      child: Text(
                        launchTitle,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                                color: scheme.primary.withValues(alpha: 0.55),
                              blurRadius: glow,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fallbackLaunchLogo(String title) {
    final safeTitle = title.trim();
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      color: primary,
      alignment: Alignment.center,
      child: Text(
        safeTitle.isEmpty ? 'APP' : safeTitle.substring(0, 1).toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 64,
          fontWeight: FontWeight.w900,
          letterSpacing: 2,
        ),
      ),
    );
  }
}