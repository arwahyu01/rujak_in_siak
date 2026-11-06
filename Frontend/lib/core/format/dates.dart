import 'package:intl/intl.dart';

final DateFormat _dateTime = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');
final DateFormat _date = DateFormat('dd MMM yyyy', 'id_ID');
final DateFormat _time = DateFormat('HH:mm', 'id_ID');
final DateFormat _apiDate = DateFormat('yyyy-MM-dd');

String formatDateTime(DateTime? value) =>
    value == null ? '-' : _dateTime.format(value.toLocal());

String formatDate(DateTime? value) =>
    value == null ? '-' : _date.format(value.toLocal());

String formatTime(DateTime? value) =>
    value == null ? '-' : _time.format(value.toLocal());

String toApiDate(DateTime value) => _apiDate.format(value);

String relativeTime(DateTime? value) {
  if (value == null) return 'Belum pernah';
  final diff = DateTime.now().difference(value.toLocal());
  if (diff.inSeconds < 60) return 'Baru saja';
  if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
  if (diff.inHours < 24) return '${diff.inHours} jam lalu';
  if (diff.inDays < 30) return '${diff.inDays} hari lalu';
  return formatDate(value);
}
