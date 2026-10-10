import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Teks UI Bahasa Indonesia. Teks app ditulis langsung di widget (satu bahasa);
/// delegate ini menerjemahkan teks bawaan Material (tooltip, date picker, dan sejenisnya).
abstract final class AppLocale {
  static const locale = Locale('id');

  static const supportedLocales = [locale];

  static const localizationsDelegates = <LocalizationsDelegate<Object>>[
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];
}
