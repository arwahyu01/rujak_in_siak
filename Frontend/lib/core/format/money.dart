import 'package:intl/intl.dart';

final NumberFormat _decimal = NumberFormat.decimalPattern('id_ID');

String formatRupiah(int amount) => 'Rp${_decimal.format(amount)}';

String formatRupiahSigned(int amount) =>
    amount < 0 ? '-${formatRupiah(amount.abs())}' : formatRupiah(amount);

String formatNumber(int value) => _decimal.format(value);
