import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_private_config.dart';
import 'pages/home_page.dart';
import 'pages/dsp_page.dart';
import 'pages/city_brgy_page.dart';
import 'pages/launch_screen.dart';
import 'services/app_customization_notifier.dart';
import 'services/import_notifier.dart';
import 'theme/ke_theme.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ImportNotifier()),
        ChangeNotifierProvider(create: (_) => AppCustomizationNotifier()..initialize()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppCustomizationNotifier>(
      builder: (context, customization, _) {
        return MaterialApp(
          title: AppPrivateConfig.appName,
          theme: KETheme.fromSeed(
            seedColor: customization.seedColor,
            brightness: Brightness.light,
          ),
          darkTheme: KETheme.fromSeed(
            seedColor: customization.seedColor,
            brightness: Brightness.dark,
          ),
          themeMode: customization.themeMode,
          home: const AppStartScreen(),
        );
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController(initialPage: 0);

  static const List<String> _tabLabels = ['Home', 'DSP', 'City/Brgy'];
  static const List<IconData> _tabIcons = [
    Icons.home,
    Icons.person,
    Icons.location_city,
  ];

  final List<Widget> _pages = [
    HomePage(),
    DSPPage(),
    CityBrgyPage(),
  ];

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    setState(() {
      _selectedIndex = index;
    });

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedTabBody() {
    return PageView(
      controller: _pageController,
      physics: const BouncingScrollPhysics(),
      onPageChanged: (index) {
        if (index == _selectedIndex) return;
        setState(() {
          _selectedIndex = index;
        });
      },
      children: List.generate(_pages.length, (index) {
        return _KeepAlivePage(
          child: TickerMode(
            enabled: _selectedIndex == index,
            child: _pages[index],
          ),
        );
      }),
    );
  }

  Widget _buildAnimatedNavItem({
    required int index,
    required String label,
    required IconData icon,
    required ColorScheme scheme,
  }) {
    final isSelected = index == _selectedIndex;

    Widget buildSelectedIcon() {
      return TweenAnimationBuilder<double>(
        key: ValueKey<String>('icon-pop-$index-$_selectedIndex'),
        tween: Tween<double>(begin: 0.9, end: 1),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.scale(scale: value, child: child);
        },
        child: Icon(
          icon,
          key: ValueKey<String>('icon-solid-$index'),
          color: scheme.primary,
          size: 24,
        ),
      );
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _onItemTapped(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(scale: animation, child: child),
                      );
                    },
                    child: isSelected
                        ? buildSelectedIcon()
                        : Text(
                            label,
                            key: ValueKey<String>('label-$index'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                              color: scheme.onSurface.withValues(alpha: 0.82),
                            ),
                          ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    width: isSelected ? 18 : 0,
                    height: 2.4,
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedBottomNav(ColorScheme scheme) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.fromLTRB(10, 4, 10, bottomInset > 0 ? 6 : 8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border(
            top: BorderSide(
              color: scheme.outline.withValues(alpha: 0.18),
              width: 0.8,
            ),
          ),
        ),
        child: Row(
          children: List.generate(_tabLabels.length, (index) {
            return _buildAnimatedNavItem(
              index: index,
              label: _tabLabels[index],
              icon: _tabIcons[index],
              scheme: scheme,
            );
          }),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ImportNotifier>(
      builder: (context, notifier, _) {
        final scheme = Theme.of(context).colorScheme;

        Widget buildProgressPanel({required Color background}) {
          return Container(
            color: background,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final op in notifier.operations)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Text(
                          op.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: scheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: op.progress,
                              minHeight: 8,
                              backgroundColor: scheme.primaryContainer,
                              valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(op.progress * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: scheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        }

        return Scaffold(
          body: _buildAnimatedTabBody(),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (notifier.isImporting) ...[
                buildProgressPanel(background: scheme.secondaryContainer),
              ],
              _buildAnimatedBottomNav(scheme),
            ],
          ),
        );
      },
    );
  }
}

class _KeepAlivePage extends StatefulWidget {
  const _KeepAlivePage({required this.child});

  final Widget child;

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin<_KeepAlivePage> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

class AppStartScreen extends StatefulWidget {
  const AppStartScreen({super.key});

  @override
  State<AppStartScreen> createState() => _AppStartScreenState();
}

class _AppStartScreenState extends State<AppStartScreen> {
  bool _showMain = false;

  void _handleLaunchDone() {
    if (!mounted) return;
    setState(() {
      _showMain = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showMain) {
      return const MainScreen();
    }

    return LaunchScreen(onDone: _handleLaunchDone);
  }
}
