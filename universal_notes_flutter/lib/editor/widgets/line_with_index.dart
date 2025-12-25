import 'package:universal_notes_flutter/editor/virtual_text_buffer.dart';

/// A helper class to associate a [Line] with its index in the buffer.
class LineWithIndex {
  /// Creates a [LineWithIndex].
  LineWithIndex(this.line, this.index);

  /// The line object.
  final Line line;

  /// The index of the line in the buffer.
  final int index;
}
