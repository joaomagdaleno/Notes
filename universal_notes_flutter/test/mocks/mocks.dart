// test/mocks/mocks.dart

import 'package:mockito/annotations.dart';
import 'package:universal_notes_flutter/repositories/note_repository.dart';
import 'package:universal_notes_flutter/services/update_service.dart';

// Esta anotação instrui o build_runner a gerar mocks para as classes listadas.
// Verifique se UpdateService está aqui.
@GenerateMocks([
  UpdateService,
  NoteRepository,
])
void main() {}
