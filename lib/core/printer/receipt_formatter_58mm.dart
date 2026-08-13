import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

import '../../domain/models/receipt_models.dart';
import '../utils/date_formatter.dart';
import '../utils/money_formatter.dart';
import 'receipt_logo.dart';

class ReceiptFormatter58mm {
  Future<List<int>> format(ReceiptData data) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    final bytes = <int>[];

    bytes.addAll(generator.reset());
    final logo = await ReceiptLogo.forWidth(
      ReceiptLogo.width58mm,
      reference: data.orderNumber,
    );
    if (logo != null) {
      bytes.addAll(generator.imageRaster(logo, align: PosAlign.center));
      bytes.addAll(generator.feed(1));
    }
    bytes.addAll(
      generator.text(
        data.outletName,
        styles: const PosStyles(
          bold: true,
          align: PosAlign.center,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      ),
    );
    bytes.addAll(generator.text(data.outletAddress, styles: _center));
    if (data.outletInstagram.isNotEmpty) {
      bytes.addAll(
        generator.text('Instagram : ${data.outletInstagram}', styles: _center),
      );
    }
    bytes.addAll(generator.text('WA: ${data.outletWhatsapp}', styles: _center));
    bytes.addAll(
      generator.text('Kasir : ${data.cashierName}', styles: _center),
    );
    bytes.addAll(generator.hr());
    bytes.addAll(generator.text('Pesanan: ${data.orderNumber}'));
    bytes.addAll(generator.text(DateFormatter.human(data.createdAt)));
    if ((data.customerPhone ?? '').isNotEmpty) {
      bytes.addAll(generator.text('HP: ${data.customerPhone}'));
    }
    if ((data.customerName ?? '').isNotEmpty) {
      bytes.addAll(generator.text('Nama Pelanggan : ${data.customerName}'));
    }
    bytes.addAll(generator.text(data.orderType));
    if (data.isDineIn && (data.tableNumber ?? '').isNotEmpty) {
      bytes.addAll(generator.text('No. Meja : ${data.tableNumber}'));
    }
    bytes.addAll(generator.hr());

    for (final item in data.items) {
      bytes.addAll(
        generator.text(item.name, styles: const PosStyles(bold: true)),
      );
      final detail = _itemDetail(item);
      if (detail.isNotEmpty) {
        bytes.addAll(generator.text(detail));
      }
      bytes.addAll(
        generator.row([
          PosColumn(text: '${item.quantity} x', width: 2),
          PosColumn(text: MoneyFormatter.format(item.unitPrice), width: 5),
          PosColumn(
            text: MoneyFormatter.format(item.subtotal),
            width: 5,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]),
      );
    }

    bytes.addAll(generator.hr());
    bytes.addAll(_amountRow(generator, 'Total', data.total, bold: true));
    bytes.addAll(_amountRow(generator, 'Bayar', data.amountPaid));
    bytes.addAll(_amountRow(generator, 'Kembali', data.changeAmount));
    bytes.addAll(generator.text('Metode: ${data.paymentMethod}'));
    bytes.addAll(generator.hr());
    bytes.addAll(generator.text(data.footer, styles: _center));
    bytes.addAll(generator.feed(2));
    bytes.addAll(generator.cut());
    return bytes;
  }

  static const _center = PosStyles(align: PosAlign.center);

  String _itemDetail(ReceiptItem item) {
    final parts = [
      item.category,
      item.temperature,
      item.sugar,
      item.method,
      item.bean,
      ...item.addons,
      item.notes,
    ].where((value) => value != null && value.trim().isNotEmpty);
    return parts.join(' / ');
  }

  List<int> _amountRow(
    Generator generator,
    String label,
    int value, {
    bool bold = false,
  }) {
    return generator.row([
      PosColumn(
        text: label,
        width: 6,
        styles: PosStyles(bold: bold),
      ),
      PosColumn(
        text: MoneyFormatter.format(value),
        width: 6,
        styles: PosStyles(align: PosAlign.right, bold: bold),
      ),
    ]);
  }
}
