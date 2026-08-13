import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/config/feature_flags.dart';
import '../../core/files/report_file_saver.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/money_formatter.dart';
import '../repositories/audit_repository_contract.dart';
import '../repositories/reports_repository_contract.dart';
import '../models/report_models.dart';

class ReportExportResult {
  const ReportExportResult({required this.fileName, required this.location});

  final String fileName;
  final String location;
}

class ReportExportUseCase {
  ReportExportUseCase({
    required ReportsRepositoryContract reportsRepository,
    required ReportFileSaver fileSaver,
    AuditRepositoryContract? auditRepository,
  }) : _reportsRepository = reportsRepository,
       _fileSaver = fileSaver,
       _auditRepository = auditRepository;

  final ReportsRepositoryContract _reportsRepository;
  final ReportFileSaver _fileSaver;
  final AuditRepositoryContract? _auditRepository;

  /// Generates a local PDF and stores it in Android's public Downloads folder.
  Future<ReportExportResult> exportPdf(
    ReportRange range, {
    String? actorUserId,
    String? actorUsername,
  }) async {
    final summary = await _reportsRepository.summary(range.start, range.end);
    final bytes = await _buildPdf(range, summary);
    final safeStart = DateFormatter.inputDate.format(range.start);
    final safeEnd = DateFormatter.inputDate.format(
      range.end.subtract(const Duration(milliseconds: 1)),
    );
    final uniqueSuffix = DateTime.now().millisecondsSinceEpoch;
    final fileName = 'laporan_talaga_${safeStart}_${safeEnd}_$uniqueSuffix.pdf';
    final location = await _fileSaver.savePdf(fileName: fileName, bytes: bytes);

    await _auditRepository?.record(
      actorUserId: actorUserId,
      actorUsername: actorUsername,
      action: 'report.export',
      entityType: 'report',
      entityId:
          '${range.start.toIso8601String()}_${range.end.toIso8601String()}',
      description: 'Laporan PDF ${range.label} diekspor',
      metadata: {
        'fileName': fileName,
        'location': location,
        'format': 'pdf',
        'start': range.start.toIso8601String(),
        'end': range.end.toIso8601String(),
      },
    );
    return ReportExportResult(fileName: fileName, location: location);
  }

  Future<Uint8List> _buildPdf(ReportRange range, ReportSummary summary) async {
    final document = pw.Document(
      title: 'Laporan Talaga Coffee POS',
      author: 'Talaga Coffee POS',
      creator: 'Talaga Coffee POS',
    );
    final products = summary.productQuantities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final categories = summary.salesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 10),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.brown300)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'TALAGA COFFEE POS',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.brown800,
                ),
              ),
              pw.Text('Laporan Penjualan'),
            ],
          ),
        ),
        footer: (context) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Halaman ${context.pageNumber} dari ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ),
        build: (context) => [
          pw.SizedBox(height: 18),
          pw.Text(
            'Ringkasan ${range.label}',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            '${DateFormatter.human(range.start)} - '
            '${DateFormatter.human(range.end.subtract(const Duration(milliseconds: 1)))}',
            style: const pw.TextStyle(color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 18),
          _pdfTable(
            headers: const ['Metrik', 'Nilai'],
            rows: [
              ['Total omzet', _money(summary.totalRevenue)],
              ['Transaksi lunas', '${summary.paidTransactionCount}'],
              ['Total tunai diterima', _money(summary.totalCashReceived)],
              ['Produk terlaris', summary.bestSellingProduct],
              if (FeatureFlags.cancelledOrdersReport)
                ['Pesanan dibatalkan', '${summary.cancelledOrderCount}'],
            ],
          ),
          pw.SizedBox(height: 22),
          _sectionTitle('Ranking Produk'),
          pw.SizedBox(height: 8),
          if (products.isEmpty)
            pw.Text('Belum ada produk terjual pada periode ini.')
          else
            _pdfTable(
              headers: const ['Peringkat', 'Produk', 'Jumlah'],
              rows: [
                for (var index = 0; index < products.length; index++)
                  [
                    '${index + 1}',
                    products[index].key,
                    '${products[index].value} unit',
                  ],
              ],
            ),
          pw.SizedBox(height: 22),
          _sectionTitle('Omzet per Kategori'),
          pw.SizedBox(height: 8),
          if (categories.isEmpty)
            pw.Text('Belum ada penjualan kategori pada periode ini.')
          else
            _pdfTable(
              headers: const ['Kategori', 'Omzet'],
              rows: [
                for (final entry in categories)
                  [entry.key, _money(entry.value)],
              ],
            ),
          pw.SizedBox(height: 18),
          pw.Text(
            'Dibuat otomatis oleh Talaga Coffee POS pada '
            '${DateFormatter.human(DateTime.now())}.',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    );

    return document.save();
  }

  pw.Widget _sectionTitle(String value) => pw.Text(
    value,
    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
  );

  pw.Widget _pdfTable({
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      headerStyle: pw.TextStyle(
        color: PdfColors.white,
        fontWeight: pw.FontWeight.bold,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.brown700),
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.brown50),
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 6),
      cellStyle: const pw.TextStyle(fontSize: 10),
    );
  }

  String _money(num value) =>
      MoneyFormatter.format(value).replaceAll('\u00a0', ' ');
}
