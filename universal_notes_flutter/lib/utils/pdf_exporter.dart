import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/painting.dart';
import 'package:flutter_drawing_board/flutter_drawing_board.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:universal_notes_flutter/models/note.dart';
import 'package:universal_notes_flutter/utils/drawing_deserializer.dart';
import 'package:universal_notes_flutter/models/paper_config.dart';

// --- Public API ---

Future<void> exportNoteToPdf(Note note, {bool share = true}) async {
  final doc = await _generatePdf(note);
  final bytes = await doc.save();

  if (share) {
    await Printing.sharePdf(bytes: bytes, filename: '${note.title}.pdf');
  } else {
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

  List<PaintObject> contents = [];
  try {
    contents = (jsonDecode(note.drawingJson!) as List)
        .cast<Map<String, dynamic>>()
        .map(paintContentFromJson)
        .whereType<PaintObject>()
        .toList();
  } catch (e) {
    return pw.Text('Error parsing drawing content: $e');
  }

  final lines = contents.whereType<Line>().toList();
  if (lines.isEmpty) return pw.SizedBox();

  return pw.Container(
    width: format.availableWidth,
    height: format.availableHeight,
    margin: const pw.EdgeInsets.only(top: 16),
    child: pw.CustomPaint(
      painter: (canvas, size) {
        for (final line in lines) {
          final path = line.points;
          if (path.isEmpty) continue;

          final isErase = line is EraserObject;

          canvas
            ..setColor(isErase ? PdfColors.white : PdfColor.fromInt(line.paint.color.value))
            ..setLineWidth(line.paint.strokeWidth)
            ..setLineCap(line.paint.strokeCap == StrokeCap.round
                ? PdfLineCap.round
                : PdfLineCap.butt)
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