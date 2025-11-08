import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/painting.dart';
import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:universal_notes_flutter/models/note.dart';

// --- Enums and Extensions for PDF Generation ---
// NOTE: These are duplicated from the editor screen. For a larger app,
// it would be best to move these to a shared model file.

enum PaperFormat { a4, letter, legal }

extension PaperFormatExtension on PaperFormat {
  Size get size {
    const double cm = 72 / 2.54;
    const double inch = 72;
    switch (this) {
      case PaperFormat.a4:
        return const Size(21.0 * cm, 29.7 * cm);
      case PaperFormat.letter:
        return const Size(8.5 * inch, 11.0 * inch);
      case PaperFormat.legal:
        return const Size(8.5 * inch, 14.0 * inch);
    }
  }

  String get label => name.toUpperCase();
}

enum PaperMargin { normal, narrow, moderate, wide }

extension PaperMarginExtension on PaperMargin {
  EdgeInsets get value {
    const double cm = 72 / 2.54;
    switch (this) {
      case PaperMargin.normal:
        return const EdgeInsets.all(2.54 * cm);
      case PaperMargin.narrow:
        return const EdgeInsets.all(1.27 * cm);
      case PaperMargin.moderate:
        return EdgeInsets.symmetric(
            vertical: 2.54 * cm, horizontal: 1.91 * cm);
      case PaperMargin.wide:
        return EdgeInsets.symmetric(
            vertical: 2.54 * cm, horizontal: 5.08 * cm);
    }
  }

  String get label => name[0].toUpperCase() + name.substring(1);
}

// --- Public API ---

Future<void> exportNoteToPdf(Note note, {bool share = true}) async {
  final doc = await _generatePdf(note);
  final bytes = await doc.save();

  if (share) {
    await Printing.sharePdf(bytes: bytes, filename: '${note.title}.pdf');
  } else {
    // Note: This saves to the app's root directory. For a real-world scenario,
    // using a package like path_provider to find a suitable downloads folder is better.
    final file = File('${note.id}.pdf');
    await file.writeAsBytes(bytes);
  }
}

// --- PDF Generation Logic ---

Future<pw.Document> _generatePdf(Note note) async {
  final pdf = pw.Document(title: note.title);

  final prefs = note.prefsJson != null ? jsonDecode(note.prefsJson!) : {};
  final format = _paperFormatFromString(prefs['format'] ?? 'a4');
  final margin = _paperMarginFromString(prefs['margin'] ?? 'normal');

  final pageTheme = pw.PageTheme(
    pageFormat: PdfPageFormat(
      format.size.width,
      format.size.height,
      marginLeft: margin.value.left,
      marginTop: margin.value.top,
      marginRight: margin.value.right,
      marginBottom: margin.value.bottom,
    ),
  );

  pdf.addPage(
    pw.MultiPage(
      pageTheme: pageTheme,
      build: (ctx) => [
        _buildHeader(note),
        if (note.content.isNotEmpty && note.content != '[{"insert":"\\n"}]')
          _buildText(ctx, note),
        if (note.drawingJson != null && note.drawingJson!.isNotEmpty)
          _buildDrawing(note, pageTheme.pageFormat),
      ],
    ),
  );

  return pdf;
}

// --- Converters ---

PaperFormat _paperFormatFromString(String? s) =>
    PaperFormat.values.firstWhere((e) => e.name == s, orElse: () => PaperFormat.a4);

PaperMargin _paperMarginFromString(String? s) =>
    PaperMargin.values.firstWhere((e) => e.name == s, orElse: () => PaperMargin.normal);

PdfColor _hexToPdfColor(String hex) {
  final h = hex.replaceFirst('#', '');
  return PdfColor.fromInt(int.parse(h, radix: 16) | 0xFF000000);
}

// --- Widget Builders ---

pw.Widget _buildHeader(Note note) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 20),
    child: pw.Text(note.title,
        style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
  );
}

pw.Widget _buildText(pw.Context ctx, Note note) {
  try {
    final delta = jsonDecode(note.content) as List<dynamic>;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: delta.map((op) => _opToPdf(op)).toList(),
    );
  } catch (e) {
    return pw.Text('Error parsing text content: $e');
  }
}

pw.Widget _opToPdf(Map<String, dynamic> op) {
  final insert = op['insert']?.toString() ?? '';
  if (insert.isEmpty) return pw.SizedBox();

  final attrs = op['attributes'] as Map<String, dynamic>? ?? {};
  pw.TextStyle style = const pw.TextStyle(fontSize: 11);

  if (attrs['bold'] == true) style = style.copyWith(fontWeight: pw.FontWeight.bold);
  if (attrs['italic'] == true) style = style.copyWith(fontStyle: pw.FontStyle.italic);
  if (attrs['underline'] == true) style = style.copyWith(decoration: pw.TextDecoration.underline);
  if (attrs['strike'] == true) style = style.copyWith(decoration: pw.TextDecoration.lineThrough);
  if (attrs['color'] != null) style = style.copyWith(color: _hexToPdfColor(attrs['color']));

  pw.BoxDecoration? decoration;
  if (attrs['background'] != null) {
      decoration = pw.BoxDecoration(color: _hexToPdfColor(attrs['background']));
  }

  if (attrs['heading'] != null) {
    final level = int.tryParse(attrs['heading'].toString()) ?? 1;
    style = style.copyWith(
        fontSize: 11 + (4 - level) * 4, fontWeight: pw.FontWeight.bold);
  }

  if (attrs['block-type'] == 'quote') {
    return pw.Container(
      margin: const pw.EdgeInsets.only(left: 10, top: 4, bottom: 4),
      padding: const pw.EdgeInsets.only(left: 8),
      decoration: const pw.BoxDecoration(
          border: pw.Border(left: pw.BorderSide(width: 2, color: PdfColors.grey400))),
      child: pw.Text(insert, style: style.copyWith(color: PdfColors.grey700)),
    );
  }

  return pw.Container(
    decoration: decoration,
    child: pw.Text(insert, style: style),
  );
}

pw.Widget _buildDrawing(Note note, PdfPageFormat format) {
  if (note.drawingJson == null || note.drawingJson!.isEmpty) return pw.SizedBox();

  final drawing = Drawing.fromJson(jsonDecode(note.drawingJson!));
  final layers = drawing.layers.whereType<PathLayerData>().toList();
  if (layers.isEmpty) return pw.SizedBox();

  return pw.Container(
    width: format.availableWidth,
    height: format.availableHeight,
    margin: const pw.EdgeInsets.only(top: 16),
    child: pw.CustomPaint(
      painter: (canvas, size) {
        for (final layer in layers) {
          final path = layer.path;
          if (path.isEmpty) continue;

          final paint = layer.paint;
          canvas
            ..setColor(PdfColor.fromInt(paint.color.value))
            ..setLineWidth(paint.strokeWidth)
            ..setStrokeCap(paint.strokeCap == StrokeCap.round
                ? PdfStrokeCap.round
                : PdfStrokeCap.butt)
            ..moveTo(path.first.dx, path.first.dy);

          for (int i = 1; i < path.length; i++) {
            canvas.lineTo(path[i].dx, path[i].dy);
          }
          canvas.strokePath();
        }
      },
    ),
  );
}
