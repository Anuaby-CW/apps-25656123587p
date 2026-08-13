import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

import '../../domain/models/receipt_models.dart';
import '../utils/date_formatter.dart';
import '../utils/money_formatter.dart';
import 'receipt_logo.dart';

class ReceiptFormatter80mm {
  Future<List<int>> format(ReceiptData data) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    final bytes = <int>[];

    bytes.addAll(generator.reset());
    final logo = await ReceiptLogo.forWidth(
      ReceiptLogo.width80mm,
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
    bytes.addAll(
      generator.text('WhatsApp: ${data.outletWhatsapp}', styles: _center),
    );
    bytes.addAll(
      generator.text('Kasir : ${data.cashierName}', styles: _center),
    );
    bytes.addAll(generator.hr());
    bytes.addAll(
      generator.row([
        PosColumn(text: 'Pesanan', width: 3),
        PosColumn(text: data.orderNumber, width: 9),
      ]),
    );
    bytes.addAll(
      generator.row([
        PosColumn(text: 'Tanggal', width: 3),
        PosColumn(text: DateFormatter.human(data.createdAt), width: 9),
      ]),
    );
    if ((data.customerName ?? '').isNotEmpty) {
      bytes.addAll(generator.text('Nama Pelanggan : ${data.customerName}'));
    }
    bytes.addAll(generator.text(data.orderType));
    if (data.isDineIn && (data.tableNumber ?? '').isNotEmpty) {
      bytes.addAll(
        generator.row([
          PosColumn(text: 'No. Meja', width: 3),
          PosColumn(text: data.tableNumber!, width: 9),
        ]),
      );
    }
    bytes.addAll(generator.hr());
    bytes.addAll(
      generator.row([
        PosColumn(
          text: 'Produk',
          width: 5,
          styles: const PosStyles(bold: true),
        ),
        PosColumn(text: 'Jml', width: 2, styles: const PosStyles(bold: true)),
        PosColumn(
          text: 'Harga',
          width: 2,
          styles: const PosStyles(align: PosAlign.right, bold: true),
        ),
        PosColumn(
          text: 'Subtotal',
          width: 3,
          styles: const PosStyles(align: PosAlign.right, bold: true),
        ),
      ]),
    );

    for (final item in data.items) {
      bytes.addAll(
        generator.row([
          PosColumn(text: item.name, width: 5),
          PosColumn(text: item.quantity.toString(), width: 2),
          PosColumn(
            text: MoneyFormatter.format(item.unitPrice),
            width: 2,
            styles: const PosStyles(align: PosAlign.right),
          ),
          PosColumn(
            text: MoneyFormatter.format(item.subtotal),
            width: 3,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]),
      );
      final detail = _itemDetail(item);
      if (detail.isNotEmpty) {
        bytes.addAll(generator.text('  $detail'));
      }
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
        width: 8,
        styles: PosStyles(bold: bold),
      ),
      PosColumn(
        text: MoneyFormatter.format(value),
        width: 4,
        styles: PosStyles(align: PosAlign.right, bold: bold),
      ),
    ]);
  }
}
