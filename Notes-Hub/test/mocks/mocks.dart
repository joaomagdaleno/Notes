import 'package:flutter/material.dart';
import 'package:mockito/annotations.dart';
import 'package:notes_hub/repositories/firestore_repository.dart';
import 'package:notes_hub/repositories/note_repository.dart';
import 'package:notes_hub/services/update_service.dart';

@GenerateNiceMocks([
  MockSpec<NoteRepository>(),
  MockSpec<FirestoreRepository>(),
  MockSpec<UpdateService>(),
  MockSpec<NavigatorObserver>(),
])
void main() {}
