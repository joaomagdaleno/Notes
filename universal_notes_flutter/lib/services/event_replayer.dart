import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:universal_notes_flutter/editor/document.dart';
import 'package:universal_notes_flutter/editor/document_manipulator.dart';
import 'package:universal_notes_flutter/models/note_event.dart';

/// Service responsible for reconstructing document states from events.
class EventReplayer {
  /// Replays a list of [events] to reconstruct the document state.
  ///
  /// If [baseline] is provided, events are applied on top of it.
  /// Otherwise, starts with an empty document.
  static DocumentModel reconstruct(
    List<NoteEvent> events, {
    DocumentModel? baseline,
  }) {
    var document = baseline ?? const DocumentModel(blocks: []);

    // Sort events by timestamp just in case, though they should come sorted from DB.
    final sortedEvents = List<NoteEvent>.from(events)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    for (final event in sortedEvents) {
      document = _applyEvent(document, event);
    }

    return document;
  }

  static DocumentModel _applyEvent(DocumentModel doc, NoteEvent event) {
    try {
      switch (event.type) {
        case NoteEventType.insert:
          return DocumentManipulator.insertText(
            doc,
            event.payload['pos'] as int,
            event.payload['text'] as String,
          ).document;

        case NoteEventType.delete:
          return DocumentManipulator.deleteText(
            doc,
            event.payload['pos'] as int,
            event.payload['len'] as int,
          ).document;

        case NoteEventType.format:
          final pos = event.payload['pos'] as int;
          final len = event.payload['len'] as int;
          final selection = TextSelection(
            baseOffset: pos,
            extentOffset: pos + len,
          );

          if (event.payload.containsKey('attr')) {
            final attrName = event.payload['attr'] as String;
            final attr = StyleAttribute.values.firstWhere(
              (e) => e.name == attrName,
              orElse: () => StyleAttribute.bold,
            );
            return DocumentManipulator.toggleStyle(
              doc,
              selection,
              attr,
            ).document;
          } else if (event.payload.containsKey('color')) {
            final colorValue = event.payload['color'] as int;
            return DocumentManipulator.applyColor(
              doc,
              selection,
              Color(colorValue),
            ).document;
          } else if (event.payload.containsKey('fontSize')) {
            final fontSize = (event.payload['fontSize'] as num).toDouble();
            return DocumentManipulator.applyFontSize(
              doc,
              selection,
              fontSize,
            ).document;
          }
          break;

        case NoteEventType.image_insert:
          return DocumentManipulator.insertImage(
            doc,
            event.payload['pos'] as int,
            event.payload['path'] as String,
          ).document;

        case NoteEventType.unknown:
          break;
      }
    } catch (e) {
      // If an event fails to replay, return current doc to avoid crashing.
      debugPrint('Error replaying event ${event.id}: $e');
    }
    return doc;
  }
}
