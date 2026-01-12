@Tags(['unit'])
library;

// The purpose of this file is to import all other files, so the coverage
// tool can generate a complete report.
// ignore_for_file: unused_import

// This file is used to generate coverage reports.
// It imports all the files in the lib folder.

import 'package:flutter_test/flutter_test.dart';
import 'package:notes_hub/editor/document_manipulator.dart';
import 'package:notes_hub/main.dart';
import 'package:notes_hub/models/document_model.dart';
import 'package:notes_hub/models/note.dart';
import 'package:notes_hub/models/paper_config.dart';
import 'package:notes_hub/models/stroke.dart';
import 'package:notes_hub/models/sync_conflict.dart';
import 'package:notes_hub/models/tag.dart';
import 'package:notes_hub/repositories/note_repository.dart';
import 'package:notes_hub/screens/about_screen.dart';
import 'package:notes_hub/screens/note_editor_screen.dart';
import 'package:notes_hub/screens/settings_screen.dart';
import 'package:notes_hub/services/backup_service.dart';
import 'package:notes_hub/services/export_service.dart';
import 'package:notes_hub/services/security_service.dart';
import 'package:notes_hub/services/update_service.dart';
import 'package:notes_hub/utils/update_helper.dart';
import 'package:notes_hub/utils/windows_update_helper.dart';
import 'package:notes_hub/widgets/context_menu_helper.dart';
import 'package:notes_hub/widgets/note_card.dart';
import 'package:notes_hub/widgets/note_simple_list_tile.dart';

void main() {
  test('coverage helper', () {
    // This test is here to make sure the file is not empty.
  });
}
