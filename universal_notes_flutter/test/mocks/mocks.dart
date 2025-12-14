import 'package:flutter/material.dart';
import 'package:mockito/annotations.dart';
import 'package:universal_notes_flutter/repositories/note_repository.dart';
import 'package:universal_notes_flutter/services/update_service.dart';

@GenerateMocks([NoteRepository, UpdateService, NavigatorObserver])
void main() {}
