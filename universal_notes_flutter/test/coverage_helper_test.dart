// The purpose of this file is to import all other files, so the coverage
// tool can generate a complete report.
// ignore_for_file: unused_import

// This file is used to generate coverage reports.
// It imports all the files in the lib folder.

import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/main.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/models/paper_config.dart';
import 'package:universal_notes_flutter/repositories/firestore_repository.dart';

import 'package:universal_notes_flutter/repositories/note_repository.dart';
import 'package:universal_notes_flutter/screens/about_screen.dart';
import 'package:universal_notes_flutter/screens/note_editor_screen.dart';
import 'package:universal_notes_flutter/screens/settings_screen.dart';
import 'package:universal_notes_flutter/services/update_service.dart';
import 'package:universal_notes_flutter/utils/update_helper.dart';
import 'package:universal_notes_flutter/utils/windows_update_helper.dart';
import 'package:universal_notes_flutter/widgets/context_menu_helper.dart';
import 'package:universal_notes_flutter/widgets/fluent_note_card.dart';
import 'package:universal_notes_flutter/widgets/note_card.dart';
import 'package:universal_notes_flutter/widgets/note_simple_list_tile.dart';

void main() {
  test('coverage helper', () {
    // This test is here to make sure the file is not empty.
  });
}
