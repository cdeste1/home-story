import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/home.dart';
import '../models/asset.dart';
import '../models/agent_profile.dart';
import '../utils/pdf_image_helpers.dart';

/// Builds the full Home Transfer PDF document.
Future<pw.Document> buildHomeTransferPdf({
  required Home home,
  required List<Asset> assets,
  AgentProfile? agent,
}) async {
  final pdf = pw.Document();

  // Accent color from agent or fallback
  final PdfColor accent = agent?.accentColor != null
      ? PdfColor.fromInt(agent!.accentColor!)
      : PdfColors.blueGrey;

  // Load logo bytes
  final Uint8List logoBytes = await loadLogoBytes();

  // Group assets by category for sections
  final Map<String, List<Asset>> groupedAssets = {};
  for (final asset in assets) {
    groupedAssets.putIfAbsent(asset.category.displayName, () => []).add(asset);
  }

  /// -----------------------
  /// COVER PAGE
  /// -----------------------
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.letter,
      margin: const pw.EdgeInsets.all(48),
      build: (_) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Logo above
            pw.Center(
              child: pw.Image(pw.MemoryImage(logoBytes), width: 120, height: 120),
            ),
            pw.SizedBox(height: 24),

            // Exterior Image or Placeholder
            pw.Container(
              height: 220,
              width: double.infinity,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(16)),
              ),
              // FIX 1: use safeImage — no crash if exteriorImagePath is null or file is missing
              child: safeImage(
                home.exteriorImagePath,
                width: double.infinity,
                height: 220,
                fit: pw.BoxFit.cover,
              ),
            ),
            pw.SizedBox(height: 36),

            // Address
            pw.Text(
              home.address,
              style: pw.TextStyle(
                fontSize: 28,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Container(height: 2, width: 48, color: accent),
            pw.SizedBox(height: 16),

            // Buyer placeholder
            pw.Text(
              'Prepared for the next homeowner by',
              style: pw.TextStyle(
                fontSize: 12,
                color: PdfColors.grey700,
              ),
            ),
            pw.Spacer(),

            // Agent Info
            if (agent != null) ...[
              // FIX 2: use safeImage — no crash if logoPath is null or file is missing
              safeImage(agent.logoPath, width: 120, height: 60, fit: pw.BoxFit.scaleDown),
              pw.SizedBox(height: 6),
              pw.Text(
                agent.name,
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                agent.brokerage,
                style: pw.TextStyle(
                  fontSize: 11,
                  color: PdfColors.grey700,
                ),
              ),
            ],
          ],
        );
      },
    ),
  );

  /// -----------------------
  /// SECTION PAGES
  /// -----------------------
  void addSection(String title, String subtitle, List<pw.Widget> content) {
    pdf.addPage(
      _sectionPage(
        title: title,
        subtitle: subtitle,
        accent: accent,
        content: content,
        logoBytes: logoBytes,
      ),
    );
  }

  /// Section 1 — Home Overview
  addSection('Home Overview', 'Key details about the property', [
    _keyValue('Address', home.address),
    _keyValue('Year Built', home.yearBuilt?.toString() ?? '—'),
    _keyValue('Square Footage', home.squareFeet?.toString() ?? '—'),
    _keyValue('Utilities', home.utilities ?? '—'),
    _keyValue('HOA Info', home.hoaInfo ?? '—'),
  ]);

  /// Section 2 — Appliances & Systems
  final List<pw.Widget> systemWidgets = [];
  for (var cat in ['Appliances', 'Systems', 'Electrical']) {
    if (groupedAssets[cat] != null) {
      systemWidgets.add(pw.Text(cat, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
      systemWidgets.addAll(groupedAssets[cat]!.map(_assetBlock));
      systemWidgets.add(pw.SizedBox(height: 12));
    }
  }
  if (systemWidgets.isNotEmpty) {
    addSection('Appliances & Systems', 'Major systems and appliances included with the home', systemWidgets);
  }

  /// Section 3 — Paint & Finishes
  final List<pw.Widget> finishWidgets = [];
  for (var cat in ['Paint', 'Finishes']) {
    if (groupedAssets[cat] != null) {
      finishWidgets.add(pw.Text(cat, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
      finishWidgets.addAll(groupedAssets[cat]!.map(_assetBlock));
      finishWidgets.add(pw.SizedBox(height: 12));
    }
  }
  if (finishWidgets.isNotEmpty) {
    addSection('Paint & Finishes', 'Room-by-room color and finish details', finishWidgets);
  }

  /// Section 4 — Documents & Receipts
  final List<pw.Widget> docWidgets = [];
  for (var cat in ['Documents', 'Receipt']) {
    if (groupedAssets[cat] != null) {
      docWidgets.add(pw.Text(cat, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
      docWidgets.addAll(groupedAssets[cat]!.map(_assetBlock));
      docWidgets.add(pw.SizedBox(height: 12));
    }
  }
  if (docWidgets.isNotEmpty) {
    addSection('Documents & Receipts', 'Room-by-room documents and receipts', docWidgets);
  }

  /// Section 5 — Other
  final List<pw.Widget> otherWidgets = [];
  for (var cat in ['Other']) {
    if (groupedAssets[cat] != null) {
      otherWidgets.add(pw.Text(cat, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
      otherWidgets.addAll(groupedAssets[cat]!.map(_assetBlock));
      otherWidgets.add(pw.SizedBox(height: 12));
    }
  }
  if (otherWidgets.isNotEmpty) {
    addSection('Other', 'Additional information', otherWidgets);
  }

  /// Section 6 — Contacts
  if (agent != null) {
    addSection('Contacts', 'Helpful contacts related to the home', [
      pw.Text(agent.name),
      pw.Text(agent.brokerage),
      if (agent.email != null) pw.Text(agent.email!),
      if (agent.phone != null) pw.Text(agent.phone!),
      // FIX 3: use safeImage here too
      safeImage(agent.logoPath, width: 120, height: 60, fit: pw.BoxFit.cover),
    ]);
  }

  /// -----------------------
  /// FINAL PAGE
  /// -----------------------
  pdf.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.letter,
      margin: const pw.EdgeInsets.all(48),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pageHeader(logoBytes, size: 50),
          pw.Spacer(),
          pw.Center(
            child: pw.Text(
              'This Home Transfer Folder was created to make home ownership easier.\nCourtesy of ${agent?.name ?? 'Your Agent'} using Home Story',
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(
                fontSize: 12,
                color: PdfColors.grey700,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  return pdf;
}

/// -----------------------
/// REUSABLE BUILDING BLOCKS
/// -----------------------
pw.Page _sectionPage({
  required String title,
  required String subtitle,
  required PdfColor accent,
  required List<pw.Widget> content,
  required Uint8List logoBytes,
}) {
  return pw.Page(
    pageFormat: PdfPageFormat.letter,
    margin: const pw.EdgeInsets.all(48),
    build: (_) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pageHeader(logoBytes, size: 50),
          pw.SizedBox(height: 16),
          pw.Text(
            title.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Container(height: 2, width: 40, color: accent),
          pw.SizedBox(height: 12),
          pw.Text(
            subtitle,
            style: pw.TextStyle(
              fontSize: 11,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 24),
          ...content,
        ],
      );
    },
  );
}

pw.Widget pageHeader(Uint8List logoBytes, {double size = 25}) {
  return pw.Row(
    mainAxisAlignment: pw.MainAxisAlignment.end,
    children: [
      pw.Image(pw.MemoryImage(logoBytes), width: size, height: size),
    ],
  );
}

pw.Widget _keyValue(String label, String value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 8),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label),
        pw.Text(value),
      ],
    ),
  );
}

pw.Widget _assetBlock(Asset asset) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 16),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 56,
          height: 56,
          margin: const pw.EdgeInsets.only(right: 12),
          // FIX 3: use safeImage — asset.imagePath may be null or file may be gone
          child: safeImage(asset.imagePath, width: 56, height: 56),
        ),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                asset.category.displayName.toUpperCase(),
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              if (asset.room != null) pw.Text(asset.room!),
              if (asset.notes != null)
                pw.Text(
                  asset.notes!,
                  style: const pw.TextStyle(fontSize: 10),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}