import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:talaga_coffee_pos/core/printer/receipt_formatter_58mm.dart';
import 'package:talaga_coffee_pos/core/printer/receipt_formatter_80mm.dart';
import 'package:talaga_coffee_pos/core/printer/receipt_logo.dart';
import 'package:talaga_coffee_pos/core/utils/locale_bootstrap.dart';
import 'package:talaga_coffee_pos/domain/models/receipt_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(LocaleBootstrap.ensureInitialized);

  test(
    'logo thermal memakai ukuran aman dan hasil resize disimpan di cache',
    () async {
      final logo58 = await ReceiptLogo.forWidth(ReceiptLogo.width58mm);
      final cachedLogo58 = await ReceiptLogo.forWidth(ReceiptLogo.width58mm);
      final logo80 = await ReceiptLogo.forWidth(ReceiptLogo.width80mm);

      expect(logo58, isNotNull);
      expect(logo58!.width, ReceiptLogo.width58mm);
      expect(logo58.height, ReceiptLogo.width58mm);
      expect(logo58.width % 8, 0);
      expect(identical(logo58, cachedLogo58), isTrue);
      expect(logo80, isNotNull);
      expect(logo80!.width, ReceiptLogo.width80mm);
      expect(logo80.height, ReceiptLogo.width80mm);
      expect(logo80.width % 8, 0);

      for (final pixel in logo58) {
        expect(pixel.r == 0 || pixel.r == pixel.maxChannelValue, isTrue);
        expect(pixel.r, pixel.g);
        expect(pixel.g, pixel.b);
      }
    },
  );

  test('struk 58 mm menempatkan raster logo sebelum nama outlet', () async {
    final bytes = await ReceiptFormatter58mm().format(_receiptData());

    final rasterIndex = _indexOfSequence(bytes, const [
      29,
      118,
      48,
      0,
      ReceiptLogo.width58mm ~/ 8,
      0,
    ]);
    final outletIndex = _indexOfSequence(bytes, ascii.encode('Talaga Coffee'));

    expect(rasterIndex, greaterThanOrEqualTo(0));
    expect(outletIndex, greaterThan(rasterIndex));
  });

  test('struk 80 mm menempatkan raster logo sebelum nama outlet', () async {
    final bytes = await ReceiptFormatter80mm().format(_receiptData());

    final rasterIndex = _indexOfSequence(bytes, const [
      29,
      118,
      48,
      0,
      ReceiptLogo.width80mm ~/ 8,
      0,
    ]);
    final outletIndex = _indexOfSequence(bytes, ascii.encode('Talaga Coffee'));

    expect(rasterIndex, greaterThanOrEqualTo(0));
    expect(outletIndex, greaterThan(rasterIndex));
  });

  test(
    'header struk menampilkan Instagram dan kasir tanpa nomor TRX',
    () async {
      final receipt = _receiptData();
      final receipts = [
        await ReceiptFormatter58mm().format(receipt),
        await ReceiptFormatter80mm().format(receipt),
      ];

      for (final bytes in receipts) {
        expect(
          _indexOfSequence(bytes, ascii.encode('Instagram : @talagacoffee')),
          greaterThanOrEqualTo(0),
        );
        expect(
          _indexOfSequence(bytes, ascii.encode('Kasir : Andi')),
          greaterThanOrEqualTo(0),
        );
        expect(_indexOfSequence(bytes, ascii.encode('TRX-001')), -1);
      }
    },
  );

  test('nomor meja hanya dicetak untuk pesanan Dine In', () async {
    final dineInReceipts = [
      await ReceiptFormatter58mm().format(
        _receiptData(orderType: 'Dine In', tableNumber: 'A03'),
      ),
      await ReceiptFormatter80mm().format(
        _receiptData(orderType: 'Dine In', tableNumber: 'A03'),
      ),
    ];
    final takeAwayReceipts = [
      await ReceiptFormatter58mm().format(
        _receiptData(orderType: 'Take Away', tableNumber: 'A03'),
      ),
      await ReceiptFormatter80mm().format(
        _receiptData(orderType: 'Take Away', tableNumber: 'A03'),
      ),
    ];

    for (final bytes in dineInReceipts) {
      expect(
        _indexOfSequence(bytes, ascii.encode('No. Meja')),
        greaterThanOrEqualTo(0),
      );
      expect(
        _indexOfSequence(bytes, ascii.encode('A03')),
        greaterThanOrEqualTo(0),
      );
    }
    for (final bytes in takeAwayReceipts) {
      expect(_indexOfSequence(bytes, ascii.encode('No. Meja')), -1);
      expect(_indexOfSequence(bytes, ascii.encode('A03')), -1);
    }
  });

  test('nama pelanggan dicetak sebelum tipe pesanan dan nomor meja', () async {
    final receipts = [
      await ReceiptFormatter58mm().format(
        _receiptData(orderType: 'Dine In', tableNumber: 'A03'),
      ),
      await ReceiptFormatter80mm().format(
        _receiptData(orderType: 'Dine In', tableNumber: 'A03'),
      ),
    ];

    for (final bytes in receipts) {
      final customerIndex = _indexOfSequence(
        bytes,
        ascii.encode('Nama Pelanggan : John Doe'),
      );
      final orderTypeIndex = _indexOfSequence(bytes, ascii.encode('Dine In'));
      final tableIndex = _indexOfSequence(bytes, ascii.encode('No. Meja'));
      expect(customerIndex, greaterThanOrEqualTo(0));
      expect(orderTypeIndex, greaterThan(customerIndex));
      expect(tableIndex, greaterThan(orderTypeIndex));
    }
  });
}

ReceiptData _receiptData({String orderType = 'Dine In', String? tableNumber}) =>
    ReceiptData(
      outletName: 'Talaga Coffee',
      outletAddress: 'Jl. Talaga',
      outletWhatsapp: '08123456789',
      outletInstagram: '@talagacoffee',
      footer: 'Terima kasih',
      orderNumber: 'ORD-001',
      createdAt: DateTime(2026, 7, 13, 10),
      cashierName: 'Andi',
      customerName: 'John Doe',
      orderType: orderType,
      tableNumber: tableNumber,
      items: [
        const ReceiptItem(
          name: 'Kopi Talaga',
          quantity: 1,
          unitPrice: 20000,
          subtotal: 20000,
        ),
      ],
      total: 20000,
      amountPaid: 25000,
      changeAmount: 5000,
    );

int _indexOfSequence(List<int> source, List<int> sequence) {
  if (sequence.isEmpty || source.length < sequence.length) {
    return -1;
  }

  for (var start = 0; start <= source.length - sequence.length; start++) {
    var matches = true;
    for (var offset = 0; offset < sequence.length; offset++) {
      if (source[start + offset] != sequence[offset]) {
        matches = false;
        break;
      }
    }
    if (matches) {
      return start;
    }
  }
  return -1;
}
