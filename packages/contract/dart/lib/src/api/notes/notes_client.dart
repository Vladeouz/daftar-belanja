// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/create_note_input.dart';
import '../models/note.dart';
import '../models/note_page.dart';
import '../models/update_note_input.dart';

part 'notes_client.g.dart';

@RestApi()
abstract class NotesClient {
  factory NotesClient(Dio dio, {String? baseUrl}) = _NotesClient;

  /// Daftar note milik user, terbaru lebih dulu.
  ///
  /// [cursor] - Nilai `nextCursor` dari halaman sebelumnya.
  @GET('/v1/notes')
  Future<NotePage> listNotes({
    @Query('cursor') String? cursor,
    @Query('limit') int? limit = 20,
  });

  /// Buat note
  @POST('/v1/notes')
  Future<Note> createNote({
    @Body() required CreateNoteInput body,
  });

  /// Satu note milik user
  @GET('/v1/notes/{id}')
  Future<Note> getNote({
    @Path('id') required String id,
  });

  /// Ubah judul dan/atau isi note
  @PATCH('/v1/notes/{id}')
  Future<Note> updateNote({
    @Path('id') required String id,
    @Body() required UpdateNoteInput body,
  });

  /// Hapus note
  @DELETE('/v1/notes/{id}')
  Future<void> deleteNote({
    @Path('id') required String id,
  });
}
