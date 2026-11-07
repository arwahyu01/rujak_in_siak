import 'package:flutter_test/flutter_test.dart';
import 'package:rujak_pos/data/services/printer_service.dart';

void main() {
  group('PrinterConfig defaults', () {
    test('auto-prints all transactions and keeps full receipt layout', () {
      const config = PrinterConfig();

      expect(config.autoPrintMode, AutoPrintMode.all);
      expect(config.compact, isFalse);
      expect(config.paperWidth, 58);
      expect(config.shouldAutoPrint(hasAwaitingPayment: false), isTrue);
      expect(config.shouldAutoPrint(hasAwaitingPayment: true), isTrue);
    });

    test('configured only requires an address', () {
      expect(const PrinterConfig(name: 'Printer').configured, isFalse);
      expect(
        const PrinterConfig(name: 'Printer', address: '00:11').configured,
        isTrue,
      );
    });
  });

  group('PrinterConfig.autoPrintMode', () {
    test('cashOnly skips awaiting-verification sales', () {
      const config = PrinterConfig(autoPrintMode: AutoPrintMode.cashOnly);

      expect(config.shouldAutoPrint(hasAwaitingPayment: false), isTrue);
      expect(config.shouldAutoPrint(hasAwaitingPayment: true), isFalse);
    });

    test('manual never auto-prints', () {
      const config = PrinterConfig(autoPrintMode: AutoPrintMode.manual);

      expect(config.shouldAutoPrint(hasAwaitingPayment: false), isFalse);
      expect(config.shouldAutoPrint(hasAwaitingPayment: true), isFalse);
    });
  });

  group('PrinterConfig.fromJson', () {
    test('migrates enabled=false to manual', () {
      final config = PrinterConfig.fromJson({'enabled': false});

      expect(config.autoPrintMode, AutoPrintMode.manual);
    });

    test('migrates enabled=true to all', () {
      final config = PrinterConfig.fromJson({'enabled': true});

      expect(config.autoPrintMode, AutoPrintMode.all);
    });

    test('migrates config without enabled to all', () {
      final config = PrinterConfig.fromJson({'address': '00:11'});

      expect(config.autoPrintMode, AutoPrintMode.all);
    });

    test('prefers auto_print_mode over legacy enabled', () {
      final config = PrinterConfig.fromJson({
        'enabled': true,
        'auto_print_mode': 'cashOnly',
      });

      expect(config.autoPrintMode, AutoPrintMode.cashOnly);
    });

    test('reads compact and paper width', () {
      final config = PrinterConfig.fromJson({
        'auto_print_mode': 'manual',
        'compact': true,
        'paper_width': 80,
      });

      expect(config.compact, isTrue);
      expect(config.paperWidth, 80);
    });
  });

  group('PrinterConfig.toJson', () {
    test('round-trips mode and compact flag', () {
      const original = PrinterConfig(
        autoPrintMode: AutoPrintMode.cashOnly,
        compact: true,
        name: 'Printer',
        address: '00:11',
        paperWidth: 72,
      );

      final restored = PrinterConfig.fromJson(original.toJson());

      expect(restored.autoPrintMode, AutoPrintMode.cashOnly);
      expect(restored.compact, isTrue);
      expect(restored.name, 'Printer');
      expect(restored.address, '00:11');
      expect(restored.paperWidth, 72);
    });

    test('does not write the legacy enabled flag', () {
      expect(const PrinterConfig().toJson().containsKey('enabled'), isFalse);
    });
  });
}
