import 'package:api_client/api_client.dart';
import 'package:get_it/get_it.dart';

import 'package:app/features/notes/data/api_note_repository.dart';
import 'package:app/features/notes/data/note_remote_data_source.dart';
import 'package:app/features/notes/domain/repositories/note_repository.dart';
import 'package:app/features/notes/domain/usecases/create_note.dart';
import 'package:app/features/notes/domain/usecases/delete_note.dart';
import 'package:app/features/notes/domain/usecases/get_note.dart';
import 'package:app/features/notes/domain/usecases/list_notes.dart';
import 'package:app/features/notes/domain/usecases/update_note.dart';
import 'package:app/features/notes/presentation/cubit/note_form_cubit.dart';
import 'package:app/features/notes/presentation/cubit/notes_list_cubit.dart';

/// Dependency fitur notes (CONTOH). Dipanggil dari `configureDependencies` (butuh `ApiClient`).
///
/// Cubit halaman dibuat baru setiap halaman dibuka (`registerFactory`) dan ditutup `BlocProvider`.
void registerNotesDependencies(GetIt c) {
  c
    ..registerLazySingleton(() => NoteRemoteDataSource(c<ApiClient>().notes))
    ..registerLazySingleton<NoteRepository>(() => ApiNoteRepository(c()))
    ..registerLazySingleton(() => ListNotes(c()))
    ..registerLazySingleton(() => GetNote(c()))
    ..registerLazySingleton(() => CreateNote(c()))
    ..registerLazySingleton(() => UpdateNote(c()))
    ..registerLazySingleton(() => DeleteNote(c()))
    ..registerFactory(() => NotesListCubit(c()))
    ..registerFactory(
      () => NoteFormCubit(
        getNote: c(),
        createNote: c(),
        updateNote: c(),
        deleteNote: c(),
      ),
    );
}
