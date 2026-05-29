import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'core/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: ValueItApp()));
}

class ValueItApp extends ConsumerWidget {
  const ValueItApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'ValueIt',
      theme: valueItTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
