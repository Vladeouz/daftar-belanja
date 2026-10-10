# app

Aplikasi Flutter Profil A (web, Android, iOS). Konvensi di `docs/conventions.md` bagian Flutter.

```
flutter run -d chrome --web-port 8081 --web-browser-flag=--incognito --dart-define-from-file=config/dev.json
flutter run -d emulator-5554 --dart-define-from-file=config/dev.json
```

Flag `--web-browser-flag=--incognito` wajib untuk web; alasannya di `docs/conventions.md` bagian "Lingkungan Flutter dan Android".
