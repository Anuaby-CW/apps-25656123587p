import 'package:flutter/services.dart';

abstract interface class ReportFileSaver {
  Future<String> savePdf({required String fileName, required Uint8List bytes});
}

/// Stores generated reports in Android's public Downloads/Talaga Coffee folder.
class AndroidDownloadsReportFileSaver implements ReportFileSaver {
  static const _channel = MethodChannel('com.talagacoffee.pos/downloads');

  @override
  Future<String> savePdf({
    required String fileName,
    required Uint8List bytes,
  }) async {
    final location = await _channel.invokeMethod<String>('saveToDownloads', {
      'fileName': fileName,
      'mimeType': 'application/pdf',
      'bytes': bytes,
    });
    if (location == null || location.isEmpty) {
      throw StateError('PDF gagal disimpan ke folder Downloads.');
    }
    return location;
  }
}
