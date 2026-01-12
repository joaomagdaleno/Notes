@Tags(['unit'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:universal_notes_flutter/services/template_service.dart';

void main() {
  group('TemplateService', () {
    test('getTemplates returns predefined templates', () {
      final templates = TemplateService.getTemplates();
      expect(templates, isNotEmpty);
      expect(templates.any((t) => t.name == 'Meeting Note'), isTrue);
      expect(templates.any((t) => t.name == 'Daily Journal'), isTrue);
      expect(templates.any((t) => t.name == 'Project Plan'), isTrue);
    });

    test('NoteTemplate properties are correct', () {
      const t = NoteTemplate(
        name: 'T',
        description: 'D',
        contentMarkdown: 'C',
      );
      expect(t.name, 'T');
      expect(t.description, 'D');
      expect(t.contentMarkdown, 'C');
    });
  });
}
