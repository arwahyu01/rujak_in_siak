import 'package:flutter_test/flutter_test.dart';
import 'package:rujak_pos/data/services/printer_service.dart';

void main() {
  const receiptNumber = 'RJS-A01-T01-0000000123';

  group('ReceiptLayout.charsPerLine', () {
    test('matches thermal font A widths', () {
      expect(ReceiptLayout.charsPerLine(58), 32);
      expect(ReceiptLayout.charsPerLine(72), 42);
      expect(ReceiptLayout.charsPerLine(80), 48);
    });
  });

  group('ReceiptLayout.transactionHeading', () {
    test('combines paid label and receipt number on one line', () {
      final lines = ReceiptLayout.transactionHeading(
        receiptNumber: receiptNumber,
        isVoided: false,
        hasAwaitingPayment: false,
        paperWidth: 58,
      );

      expect(lines, ['LUNAS · $receiptNumber']);
    });

    test('combines void label and receipt number on one line', () {
      final lines = ReceiptLayout.transactionHeading(
        receiptNumber: receiptNumber,
        isVoided: true,
        hasAwaitingPayment: false,
        paperWidth: 58,
      );

      expect(lines, ['VOID · $receiptNumber']);
    });

    test('keeps the mandated pending label on its own line', () {
      final lines = ReceiptLayout.transactionHeading(
        receiptNumber: receiptNumber,
        isVoided: false,
        hasAwaitingPayment: true,
        paperWidth: 58,
      );

      expect(lines, ['MENUNGGU VERIFIKASI PEMBAYARAN', receiptNumber]);
    });

    test('falls back to two lines when the number is too long', () {
      final lines = ReceiptLayout.transactionHeading(
        receiptNumber: 'RJS-A01-T01-0000000123456789',
        isVoided: false,
        hasAwaitingPayment: false,
        paperWidth: 58,
      );

      expect(lines, ['LUNAS', 'RJS-A01-T01-0000000123456789']);
    });
  });

  group('ReceiptLayout.itemLines', () {
    test('fits a name that previously wrapped in the 8/12 column', () {
      final lines = ReceiptLayout.itemLines(
        label: '2x Nasi Goreng Spesial',
        amount: 'Rp35.000',
        paperWidth: 58,
      );

      expect(lines, ['2x Nasi Goreng Spesial  Rp35.000']);
      expect(lines.single.length, 32);
    });

    test('keeps a long amount on the first line', () {
      final lines = ReceiptLayout.itemLines(
        label: '2x Nasi Goreng Spesial',
        amount: 'Rp1.000.000',
        paperWidth: 58,
      );

      expect(lines, hasLength(2));
      expect(lines.first.endsWith('Rp1.000.000'), isTrue);
      expect(lines.first.length, 32);
      expect(lines.last, 'Spesial');
    });

    test('wraps long names with the amount on the first line', () {
      final lines = ReceiptLayout.itemLines(
        label: '1x Nasi Goreng Spesial Dengan Telur Dan Kerupuk',
        amount: 'Rp35.000',
        paperWidth: 58,
      );

      expect(lines.length, greaterThan(1));
      expect(lines.first.endsWith('Rp35.000'), isTrue);
      expect(lines.first.length, lessThanOrEqualTo(32));
      expect(lines.skip(1).every((line) => line.length <= 32), isTrue);
    });
  });

  group('ReceiptLayout.wrapWords', () {
    test('breaks at word boundaries', () {
      expect(ReceiptLayout.wrapWords('alpha beta gamma', 10), [
        'alpha beta',
        'gamma',
      ]);
    });

    test('hard-splits a word longer than the line', () {
      expect(ReceiptLayout.wrapWords('abcdefghijkl', 5), [
        'abcde',
        'fghij',
        'kl',
      ]);
    });
  });
}
