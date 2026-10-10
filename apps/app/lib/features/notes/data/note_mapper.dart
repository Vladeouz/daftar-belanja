import 'package:api_client/api_client.dart' as dto;

import 'package:app/features/notes/domain/entities/note.dart';
import 'package:app/features/notes/domain/entities/note_page.dart';

/// DTO `Note` → entity. Timestamp sudah UTC (API mengirim ISO 8601 berakhiran `Z`).
Note noteFromDto(dto.Note note) => Note(
  id: note.id,
  title: note.title,
  body: note.body,
  createdAt: note.createdAt,
  updatedAt: note.updatedAt,
);

NotePage notePageFromDto(dto.NotePage page) => NotePage(
  items: List.unmodifiable(page.items.map(noteFromDto)),
  nextCursor: page.nextCursor,
);
