/// Consolidated editor tests for Notes
@Tags(['unit', 'widget'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'editor/document_adapter.suite.dart' as adapter;
import 'editor/document_manipulator.suite.dart' as manipulator;
import 'editor/editor_widget.suite.dart' as widget;
import 'editor/editor_widget_reading.suite.dart' as reading;
import 'editor/history_manager.suite.dart' as history;
import 'editor/markdown_converter.suite.dart' as markdown;
import 'editor/snippet_converter.suite.dart' as snippet;
import 'editor/virtual_text_buffer.suite.dart' as vtb;

void main() {
  adapter.main();
  manipulator.main();
  reading.main();
  widget.main();
  history.main();
  markdown.main();
  snippet.main();
  vtb.main();
}
