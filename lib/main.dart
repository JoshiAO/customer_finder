import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/home_page.dart';
import 'pages/dsp_page.dart';
import 'pages/city_brgy_page.dart';
import 'pages/launch_screen.dart';
import 'services/import_notifier.dart';
import 'theme/ke_theme.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ImportNotifier(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kenea Customers',
      theme: KETheme.light(),
      home: const AppStartScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    HomePage(),
    DSPPage(),
    CityBrgyPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
          body: _pages[_selectedIndex],
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (notifier.isImporting) ...[
                buildProgressPanel(background: scheme.secondaryContainer),
              ],
              BottomNavigationBar(
                items: const <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person),
                    label: 'DSP',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.location_city),
                    label: 'City/Brgy',
                  ),
                ],
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
              ),
            ],
          ),
        );
      },
    );
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
