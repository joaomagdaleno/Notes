@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/services/backup_service.dart';

void main() {
  group('RestoreResult', () {
    test('summary should format correctly with mixed items', () {
      const result = RestoreResult(
        notesImported: 2,
        foldersImported: 1,
        versionsImported: 3,
        conflictsSkipped: 1,
      );

      expect(result.summary, '2 notas, 1 pastas, 3 versões, 1 ignorados');
    });

    test('summary should only include non-zero items', () {
      const result = RestoreResult(
        notesImported: 5,
        foldersImported: 0,
        versionsImported: 0,
        conflictsSkipped: 2,
      );

      expect(result.summary, '5 notas, 2 ignorados');
    });

    test('summary should return default message when all are zero', () {
      const result = RestoreResult(
        notesImported: 0,
        foldersImported: 0,
        versionsImported: 0,
        conflictsSkipped: 0,
      );

      expect(result.summary, 'Nenhum item importado');
    });

    test('isSuccess should be true when errors are empty', () {
      const result = RestoreResult(
        notesImported: 1,
        foldersImported: 1,
        versionsImported: 1,
        conflictsSkipped: 0,
      );
      expect(result.isSuccess, true);
    });

    test('isSuccess should be false when errors exist', () {
      const result = RestoreResult(
        notesImported: 1,
        foldersImported: 1,
        versionsImported: 1,
        conflictsSkipped: 0,
        errors: ['Error'],
      );
      expect(result.isSuccess, false);
    });
  });
}
