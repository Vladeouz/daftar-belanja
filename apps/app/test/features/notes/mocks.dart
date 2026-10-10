import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:app/features/notes/data/note_remote_data_source.dart';
import 'package:app/features/notes/domain/entities/note.dart';
import 'package:app/features/notes/domain/repositories/note_repository.dart';
import 'package:app/features/notes/domain/usecases/create_note.dart';
import 'package:app/features/notes/domain/usecases/delete_note.dart';
import 'package:app/features/notes/domain/usecases/get_note.dart';
import 'package:app/features/notes/domain/usecases/list_notes.dart';
import 'package:app/features/notes/domain/usecases/update_note.dart';
import 'package:app/features/notes/presentation/cubit/note_form_cubit.dart';
import 'package:app/features/notes/presentation/cubit/note_form_state.dart';
import 'package:app/features/notes/presentation/cubit/notes_list_cubit.dart';
import 'package:app/features/notes/presentation/cubit/notes_list_state.dart';

class MockNoteRepository extends Mock implements NoteRepository {}

class MockNoteRemoteDataSource extends Mock implements NoteRemoteDataSource {}

class MockListNotes extends Mock implements ListNotes {}

class MockGetNote extends Mock implements GetNote {}

class MockCreateNote extends Mock implements CreateNote {}

class MockUpdateNote extends Mock implements UpdateNote {}

class MockDeleteNote extends Mock implements DeleteNote {}

class MockNotesListCubit extends MockCubit<NotesListState>
    implements NotesListCubit {}

class MockNoteFormCubit extends MockCubit<NoteFormState>
    implements NoteFormCubit {}

/// Note contoh untuk test, sama dengan [noteJson].
final testNote = Note(
  id: '6f1c2f0e-8a3b-4c5d-9e7f-0a1b2c3d4e5f',
  title: 'Belanja',
  body: 'Susu dan roti',
  createdAt: DateTime.utc(2026, 10, 1, 8, 30),
  updatedAt: DateTime.utc(2026, 10, 1, 9),
);

/// Bentuk JSON `Note` dari API untuk [testNote].
const noteJson = {
  'id': '6f1c2f0e-8a3b-4c5d-9e7f-0a1b2c3d4e5f',
  'title': 'Belanja',
  'body': 'Susu dan roti',
  'createdAt': '2026-10-01T08:30:00.000Z',
  'updatedAt': '2026-10-01T09:00:00.000Z',
};

/// Note ke-[i] untuk test daftar (id `note-<i>`, judul `Catatan <i>`).
Note noteNo(int i) => Note(
  id: 'note-$i',
  title: 'Catatan $i',
  body: 'Isi $i',
  createdAt: DateTime.utc(2026, 10, 1, 8, i),
  updatedAt: DateTime.utc(2026, 10, 1, 8, i),
);
