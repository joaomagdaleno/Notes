import 'dart:convert';
import 'dart:io';

import 'package:notes_hub/editor/document.dart';
import 'package:notes_hub/editor/document_adapter.dart';
import 'package:notes_hub/models/note.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// A service to handle exporting notes to different formats.
class ExportService {
  /// Exports the given [note] to a plain text file.
  Future<void> exportToTxt(Note note) async {
    final document = DocumentAdapter.fromJson(note.content);
    final plainText = document.toPlainText();
    await Printing.sharePdf(
      bytes: utf8.encode(plainText),
      filename: '${_sanitizeFilename(note.title)}.txt',
    );
  }

  /// Exports the given [note] to a PDF file, preserving rich text formatting.
  Future<void> exportToPdf(Note note) async {
    final document = DocumentAdapter.fromJson(note.content);
    final pdf = pw.Document()
      ..addPage(
        pw.MultiPage(
          build: (pw.Context context) {
            return _buildPdfWidgets(document);
          },
        ),
      );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: '${_sanitizeFilename(note.title)}.pdf',
    );
  }

  List<pw.Widget> _buildPdfWidgets(DocumentModel document) {
    final widgets = <pw.Widget>[];
    for (final block in document.blocks) {
      if (block is TextBlock) {
        final spans = block.spans.map((span) {
          final decorations = <pw.TextDecoration>[];
          if (span.isUnderline) {
            decorations.add(pw.TextDecoration.underline);
          }
          if (span.isStrikethrough) {
            decorations.add(pw.TextDecoration.lineThrough);
          }
          return pw.TextSpan(
            text: span.text,
            style: pw.TextStyle(
              fontWeight: span.isBold
                  ? pw.FontWeight.bold
                  : pw.FontWeight.normal,
              fontStyle: span.isItalic
                  ? pw.FontStyle.italic
                  : pw.FontStyle.normal,
              decoration: pw.TextDecoration.combine(decorations),
              fontSize: span.fontSize,
              color: span.color != null
                  ? PdfColor.fromInt(span.color!.toARGB32())
                  : null,
            ),
          );
        }).toList();
        widgets.add(
          pw.Wrap(
            children: [pw.RichText(text: pw.TextSpan(children: spans))],
          ),
        );
      } else if (block is ImageBlock) {
        final file = File(block.imagePath);
        if (file.existsSync()) {
          final image = pw.MemoryImage(file.readAsBytesSync());
          widgets.add(pw.Image(image));
        }
      }
    }
    return widgets;
  }

  String _sanitizeFilename(String filename) {
    return filename.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }
}
