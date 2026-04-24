import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/models/thought.dart';
import 'core/storage/thought_repository.dart';
import 'core/agent/providers.dart';
import 'shared/theme/app_theme.dart';
import 'shared/widgets/app_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Init Hive
  await Hive.initFlutter();
  Hive.registerAdapter(ThoughtAdapter());

  // Init repository
  final repo = ThoughtRepository();
  await repo.init();

  runApp(
    ProviderScope(
      overrides: [
        thoughtRepositoryProvider.overrideWithValue(repo),
      ],
      child: const ThoughtManagerApp(),
    ),
  );
}

class ThoughtManagerApp extends ConsumerWidget {
  const ThoughtManagerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Could add a theme mode provider here later
    return MaterialApp(
      title: 'ThoughtManager',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      home: const AppShell(),
      debugShowCheckedModeBanner: false,
    );
  }
}
