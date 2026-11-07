import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/services/printer_service.dart';

class PrinterSettingsScreen extends ConsumerStatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  ConsumerState<PrinterSettingsScreen> createState() =>
      _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends ConsumerState<PrinterSettingsScreen> {
  PrinterConfig _config = const PrinterConfig();
  List<BluetoothDevice> _devices = const [];
  bool _bluetoothOn = false;
  bool _connected = false;
  bool _loading = true;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final printer = ref.read(printerServiceProvider);
    try {
      final config = await printer.loadConfig();
      var on = false;
      var connected = false;
      var devices = const <BluetoothDevice>[];
      String? error;
      try {
        on = await printer.isBluetoothOn();
        if (on) {
          connected = await printer.isConnectedTo(config);
          devices = await printer.bondedDevices();
        }
      } on AppException catch (e) {
        error = e.message;
      } catch (_) {
        error =
            'Tidak dapat membaca perangkat Bluetooth. Pastikan izin Bluetooth '
            'diberikan pada aplikasi.';
      }
      if (!mounted) return;
      setState(() {
        _config = config;
        _bluetoothOn = on;
        _connected = connected;
        _devices = devices;
        _error = error;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AppException.unknown(error).message;
      });
    }
  }

  Future<void> _save() async {
    final printer = ref.read(printerServiceProvider);
    setState(() {
      _busy = true;
      _error = null;
    });
    var saved = false;
    try {
      await printer.saveConfig(_config);
      saved = true;
      var connected = false;
      if (_bluetoothOn && _config.hasAddress) {
        await printer.connect(_config);
        connected = true;
      }
      if (!mounted) return;
      setState(() => _connected = connected);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            connected
                ? 'Printer tersimpan dan terhubung.'
                : _config.hasAddress
                ? 'Pengaturan tersimpan. Nyalakan Bluetooth untuk '
                      'menghubungkan printer.'
                : 'Pengaturan printer tersimpan.',
          ),
        ),
      );
    } on AppException catch (error) {
      if (!mounted) return;
      setState(
        () => _error = saved
            ? 'Pengaturan tersimpan, tetapi koneksi gagal: ${error.message}'
            : error.message,
      );
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _error = saved
            ? 'Pengaturan tersimpan, tetapi printer tidak dapat dihubungkan. '
                  'Pastikan printer menyala dan sudah dipasangkan.'
            : 'Gagal menyimpan pengaturan printer.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _testPrint() async {
    final printer = ref.read(printerServiceProvider);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await printer.testPrint(_config);
      if (!mounted) return;
      setState(() => _connected = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tes cetak dikirim ke printer.')),
      );
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() {
        _connected = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _connected = false;
        _error =
            'Tes cetak gagal. Pastikan printer menyala, kertas terpasang, '
            'dan Bluetooth aktif.';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disconnect() async {
    final printer = ref.read(printerServiceProvider);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await printer.disconnect();
      if (!mounted) return;
      setState(() => _connected = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Koneksi printer diputuskan.')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openBluetoothSettings() async {
    await ref.read(printerServiceProvider).openBluetoothSettings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Printer Bluetooth'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            tooltip: 'Muat ulang',
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      body: _loading
          ? const AppLoading(label: 'Memuat printer…')
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.xxl,
              ),
              children: [
                InfoBanner(
                  message: _connected
                      ? 'Printer terhubung dan siap mencetak.'
                      : _bluetoothOn
                      ? 'Bluetooth aktif. Pilih printer yang sudah dipasangkan.'
                      : 'Bluetooth belum aktif. Nyalakan Bluetooth lalu muat ulang.',
                  tone: _connected
                      ? StatusTone.success
                      : _bluetoothOn
                      ? StatusTone.info
                      : StatusTone.warning,
                  icon: _connected
                      ? Icons.bluetooth_connected_rounded
                      : _bluetoothOn
                      ? Icons.bluetooth_rounded
                      : Icons.bluetooth_disabled_rounded,
                  action: _bluetoothOn
                      ? null
                      : TextButton(
                          onPressed: _openBluetoothSettings,
                          child: const Text('Buka pengaturan'),
                        ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  InfoBanner(
                    message: _error!,
                    tone: StatusTone.danger,
                    icon: Icons.error_outline_rounded,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonFormField<AutoPrintMode>(
                          initialValue: _config.autoPrintMode,
                          decoration: const InputDecoration(
                            labelText: 'Cetak struk otomatis',
                            helperText:
                                'Hanya tunai: struk non-tunai dicetak manual '
                                'saat menunggu verifikasi.',
                          ),
                          items: [
                            for (final mode in AutoPrintMode.values)
                              DropdownMenuItem(
                                value: mode,
                                child: Text(mode.label),
                              ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _config = _config.copyWith(autoPrintMode: value);
                            });
                          },
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _config.compact,
                          title: const Text('Mode hemat kertas'),
                          subtitle: const Text(
                            'Sembunyikan nama outlet, telepon, dan footer struk.',
                          ),
                          onChanged: (value) {
                            setState(() {
                              _config = _config.copyWith(compact: value);
                            });
                          },
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedAddress,
                          decoration: const InputDecoration(
                            labelText: 'Perangkat printer',
                            helperText:
                                'Daftar berisi perangkat Bluetooth yang sudah dipasangkan.',
                          ),
                          items: [
                            for (final device in _devices)
                              DropdownMenuItem(
                                value: device.address,
                                child: Text(
                                  device.name ?? device.address ?? 'Printer',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: (value) {
                            final matches = _devices.where(
                              (item) => item.address == value,
                            );
                            final device = matches.isEmpty
                                ? null
                                : matches.first;
                            setState(() {
                              _config = _config.copyWith(
                                name: device?.name,
                                address: value,
                              );
                            });
                          },
                        ),
                        if (_devices.isEmpty) ...[
                          const SizedBox(height: AppSpacing.sm),
                          const Text(
                            'Tidak ada perangkat terpasang. Pasangkan printer '
                            'melalui pengaturan Bluetooth Android.',
                            style: TextStyle(
                              color: AppColors.inkMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        DropdownButtonFormField<int>(
                          initialValue: _config.paperWidth,
                          decoration: const InputDecoration(
                            labelText: 'Lebar kertas',
                          ),
                          items: const [
                            DropdownMenuItem(value: 58, child: Text('58 mm')),
                            DropdownMenuItem(value: 72, child: Text('72 mm')),
                            DropdownMenuItem(value: 80, child: Text('80 mm')),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() {
                              _config = _config.copyWith(paperWidth: value);
                            });
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        FilledButton.icon(
                          onPressed: _busy ? null : _save,
                          icon: _busy
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(
                            _busy
                                ? 'Menyimpan…'
                                : _bluetoothOn
                                ? 'Simpan & hubungkan'
                                : 'Simpan pengaturan',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        OutlinedButton.icon(
                          onPressed:
                              _busy || !_bluetoothOn || !_config.hasAddress
                              ? null
                              : _testPrint,
                          icon: const Icon(Icons.receipt_long_outlined),
                          label: const Text('Tes cetak'),
                        ),
                        if (_connected) ...[
                          const SizedBox(height: AppSpacing.xs),
                          TextButton.icon(
                            onPressed: _busy ? null : _disconnect,
                            icon: const Icon(Icons.link_off_rounded),
                            label: const Text('Putuskan koneksi printer'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const InfoBanner(
                  message:
                      'Printer harus mendukung ESC/POS. Cetak struk tidak pernah '
                      'membatalkan transaksi; struk gagal masuk ke antrean cetak.',
                  tone: StatusTone.info,
                  icon: Icons.info_outline_rounded,
                ),
              ],
            ),
    );
  }

  String? get _selectedAddress {
    final address = _config.address;
    if (address == null) return null;
    return _devices.any((device) => device.address == address) ? address : null;
  }
}
