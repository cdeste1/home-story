import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

Future<Uint8List?> loadImageBytes(String path) async {
  try {
    final file = File(path);
    if (!await file.exists()) return null;
    return await file.readAsBytes();
  } catch (_) {
    return null;
  }
}

/// Returns null instead of throwing if the file is missing or path is null.
Uint8List? loadImageBytesSync(String? path) {
  if (path == null) return null;
  try {
    final file = File(path);
    if (!file.existsSync()) return null;
    return file.readAsBytesSync();
  } catch (_) {
    return null;
  }
}

Future<Uint8List> loadLogoBytes() async {
  return (await rootBundle.load('assets/images/logo.png')).buffer.asUint8List();
}

/// Returns a pw.Widget — either the image or a grey placeholder box.
/// Never pass double.infinity for width/height; use null to let it size naturally.
pw.Widget safeImage(
  String? path, {
  double? width,
  double? height,
  pw.BoxFit fit = pw.BoxFit.cover,
}) {
  final bytes = loadImageBytesSync(path);
  if (bytes != null) {
    return pw.Image(pw.MemoryImage(bytes), width: width, height: height, fit: fit);
  }
  // Placeholder — only sized if explicit dimensions were provided
  return pw.Container(
    width: width,
    height: height,
    decoration: pw.BoxDecoration(
      color: PdfColors.grey200,
      borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
    ),
    child: pw.Center(
      child: pw.Text(
        path == null ? '' : '!',
        style: pw.TextStyle(color: PdfColors.grey500, fontSize: 10),
      ),
    ),
  );
}