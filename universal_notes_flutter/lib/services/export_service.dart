import 'dart:convert';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:universal_notes_flutter/editor/document.dart';
import 'package:universal_notes_flutter/editor/document_adapter.dart';
import 'package:universal_notes_flutter/models/note.dart';

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
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) {
          return [
            _buildPdfContent(document),
          ];
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: '${_sanitizeFilename(note.title)}.pdf',
    );
  }

  pw.Widget _buildPdfContent(DocumentModel document) {
    final spans = document.spans.map((span) {
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
          fontWeight: span.isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontStyle: span.isItalic ? pw.FontStyle.italic : pw.FontStyle.normal,
          decoration: pw.TextDecoration.combine(decorations),
          fontSize: span.fontSize,
          color: span.color != null
              ? PdfColor.fromInt(span.color!.value)
              : null,
        ),
      );
    }).toList();

    return pw.Wrap(
      children: [pw.RichText(text: pw.TextSpan(children: spans))],
    );
  }

  String _sanitizeFilename(String filename) {
    return filename.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }
}
