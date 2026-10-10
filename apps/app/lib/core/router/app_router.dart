import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';

import 'package:app/core/di/injection.dart';
import 'package:app/features/auth/presentation/cubit/auth_session_cubit.dart';
import 'package:app/features/auth/presentation/cubit/auth_session_state.dart';
import 'package:app/features/auth/presentation/cubit/login_cubit.dart';
import 'package:app/features/auth/presentation/cubit/register_cubit.dart';
import 'package:app/features/auth/presentation/pages/login_page.dart';
import 'package:app/features/auth/presentation/pages/register_page.dart';
import 'package:app/features/notes/domain/entities/note.dart';
import 'package:app/features/notes/presentation/cubit/note_form_cubit.dart';
import 'package:app/features/notes/presentation/cubit/notes_list_cubit.dart';
import 'package:app/features/notes/presentation/pages/note_form_page.dart';
import 'package:app/features/notes/presentation/pages/notes_page.dart';

/// Path rute app. Fitur menambah path di sini dan rutenya di [createRouter].
abstract final class AppRoutes {
  static const home = '/';
  static const login = '/login';
  static const register = '/register';
  static const notes = '/notes';
  static const noteNew = '/notes/new';
  static String note(String id) => '/notes/$id';

  /// Rute yang boleh dibuka tanpa login. Rute lain dilindungi.
  static const public = {login, register};
}

/// Router app (go_router).
///
/// - Rute terlindungi (butuh login) ditaruh di `routes` milik `ShellRoute`, yang memasang
///   [AuthSessionCubit] untuk halaman di dalamnya (misalnya `SignOutButton`).
/// - Redirect: belum login + rute terlindungi → login; sudah login + rute publik → beranda.
///   Dievaluasi ulang setiap kali [AuthSessionCubit] berubah (login, logout, token dicabut).
/// - Cubit halaman diambil dari [container] (default `getIt`) dan dipasang dengan `BlocProvider`.
GoRouter createRouter({
  GetIt? container,
  String initialLocation = AppRoutes.home,
}) {
  final c = container ?? getIt;
  final session = c<AuthSessionCubit>();
  // `context.push` ikut mengubah URL (web): tombol kembali browser menutup halaman yang
  // di-push, dan muat ulang membuka halaman yang sama (misalnya `/notes/<id>`).
  GoRouter.optionURLReflectsImperativeAPIs = true;

  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: _StreamListenable(session.stream),
    redirect: (context, state) => _authRedirect(session.state, state),
    routes: [
      GoRoute(path: AppRoutes.home, redirect: (_, _) => AppRoutes.notes),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => BlocProvider(
          create: (_) => c<LoginCubit>(),
          child: const LoginPage(),
        ),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => BlocProvider(
          create: (_) => c<RegisterCubit>(),
          child: const RegisterPage(),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            BlocProvider.value(value: session, child: child),
        routes: [
          GoRoute(
            path: AppRoutes.notes,
            builder: (context, state) => BlocProvider(
              create: (_) => c<NotesListCubit>()..load(),
              child: const NotesPage(),
            ),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => BlocProvider(
                  create: (_) => c<NoteFormCubit>(),
                  child: const NoteFormPage(),
                ),
              ),
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  // `extra` berisi note dari daftar; kosong bila dibuka lewat URL
                  // (misalnya muat ulang di web), maka note dimuat dari API.
                  final note = state.extra;
                  return BlocProvider(
                    create: (_) {
                      final cubit = c<NoteFormCubit>();
                      if (note is Note) {
                        cubit.edit(note);
                      } else {
                        cubit.load(id);
                      }
                      return cubit;
                    },
                    child: NoteFormPage(noteId: id),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => const NotFoundPage(),
  );
}

String? _authRedirect(AuthSessionState session, GoRouterState state) {
  final isPublic = AppRoutes.public.contains(state.matchedLocation);
  return switch (session) {
    Unauthenticated() when !isPublic => AppRoutes.login,
    Authenticated() when isPublic => AppRoutes.home,
    _ => null,
  };
}

/// `refreshListenable` dari stream Cubit. Langganan berakhir saat Cubit ditutup
/// (stream selesai); Cubit sesi hidup selama app.
class _StreamListenable extends ChangeNotifier {
  _StreamListenable(Stream<Object?> stream) {
    stream.listen((_) => notifyListeners());
  }
}

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Halaman tidak ditemukan')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Halaman yang Anda buka tidak ada.'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Kembali ke beranda'),
            ),
          ],
        ),
      ),
    );
  }
}
