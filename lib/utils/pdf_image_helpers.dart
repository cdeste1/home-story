import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;

Future<Uint8List?> loadImageBytes(String path) async {
  try {
    final file = File(path);
    if (!await file.exists()) return null;
    return await file.readAsBytes();
  } catch (_) {
    return null;
  }
}

Uint8List loadImageBytesSync(String path) {
  final file = File(path);
  return file.readAsBytesSync();
}

Future<Uint8List> loadLogoBytes() async {
  return (await rootBundle.load('assets/images/logo.png')).buffer.asUint8List();
}