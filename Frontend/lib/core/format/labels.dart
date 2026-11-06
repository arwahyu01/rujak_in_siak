import '../widgets/status_chip.dart';

String paymentMethodLabel(String method) => switch (method) {
  'cash' => 'Tunai',
  'qris' => 'QRIS',
  'transfer' => 'Transfer',
  'ewallet' => 'E-Wallet',
  _ => method,
};

String orderTypeLabel(String type) => switch (type) {
  'dine_in' => 'Makan di tempat',
  'take_away' => 'Bawa pulang',
  'delivery' => 'Antar',
  _ => type,
};

String paymentStatusLabel(String status) => switch (status) {
  'paid' => 'Lunas',
  'partially_paid' => 'Dibayar sebagian',
  'awaiting_verification' => 'Menunggu verifikasi',
  'partially_refunded' => 'Refund sebagian',
  'refunded' => 'Refund',
  'cancelled' => 'Dibatalkan',
  'confirmed' => 'Terkonfirmasi',
  'rejected' => 'Ditolak',
  'recorded' => 'Tercatat',
  _ => 'Belum dibayar',
};

StatusTone paymentStatusTone(String status) => switch (status) {
  'paid' || 'confirmed' => StatusTone.success,
  'awaiting_verification' || 'partially_paid' => StatusTone.warning,
  'refunded' || 'partially_refunded' => StatusTone.info,
  'cancelled' || 'rejected' => StatusTone.danger,
  _ => StatusTone.neutral,
};

String outboxStatusLabel(String status) => switch (status) {
  'pending' => 'Menunggu',
  'blocked_dependency' => 'Menunggu data terkait',
  'conflict' => 'Konflik',
  'rejected' => 'Ditolak',
  'upgrade_required' => 'Perlu pembaruan aplikasi',
  'synced' => 'Tersinkron',
  _ => status,
};

StatusTone outboxStatusTone(String status) => switch (status) {
  'synced' => StatusTone.success,
  'pending' || 'blocked_dependency' => StatusTone.warning,
  'conflict' || 'rejected' || 'upgrade_required' => StatusTone.danger,
  _ => StatusTone.neutral,
};
