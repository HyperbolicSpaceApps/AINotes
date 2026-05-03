import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/chat/chat_screen.dart';
import '../../features/thoughts/thoughts_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../core/agent/providers.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _currentIndex = 0;

  final _screens = const [
    ChatScreen(),
    ThoughtsScreen(),
    SettingsScreen(),
  ];

  final _titles = ['ThoughtManager', 'Thoughts', 'Settings'];

  @override
  Widget build(BuildContext context) {
    final thoughtCount = ref.watch(thoughtsProvider).length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF7F77DD),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.auto_awesome, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text(_titles[_currentIndex]),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            selectedIcon: Icon(Icons.chat_bubble),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: thoughtCount > 0,
              label: Text('$thoughtCount'),
              child: const Icon(Icons.folder_outlined),
            ),
            selectedIcon: const Icon(Icons.folder),
            label: 'Thoughts',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
