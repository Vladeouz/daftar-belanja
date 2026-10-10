import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:app/core/l10n/app_locale.dart';
import 'package:app/core/router/app_router.dart';
import 'package:app/core/theme/app_theme.dart';

class App extends StatefulWidget {
  const App({super.key, this.router});

  /// Router dari luar untuk test; default [createRouter].
  final GoRouter? router;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final GoRouter _router = widget.router ?? createRouter();

  @override
  void dispose() {
    if (widget.router == null) {
      _router.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Profil A',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      locale: AppLocale.locale,
      supportedLocales: AppLocale.supportedLocales,
      localizationsDelegates: AppLocale.localizationsDelegates,
      routerConfig: _router,
    );
  }
}
