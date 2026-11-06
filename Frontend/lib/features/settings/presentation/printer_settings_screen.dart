import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
      var devices = const <BluetoothDevice>[];
      String? error;
      try {
        on = await printer.isBluetoothOn();
        devices = await printer.bondedDevices();
      } catch (e) {
        error =
            'Tidak dapat membaca perangkat Bluetooth. Pastikan izin Bluetooth '
            'diberikan pada aplikasi.';
      }
      if (!mounted) return;
      setState(() {
        _config = config;
        _bluetoothOn = on;
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
    try {
      if (_config.configured) {
        await printer.connect(_config);
      }
      await printer.saveConfig(_config);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _config.configured
                ? 'Printer tersimpan dan terhubung.'
                : 'Pengaturan printer tersimpan.',
          ),
        ),
      );
    } on AppException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } catch (error) {
      if (!mounted) return;
      setState(
        () => _error =
            'Gagal menghubungkan printer. Pastikan printer menyala dan '
            'sudah dipasangkan (paired) di pengaturan Bluetooth Android.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
                  message: _bluetoothOn
                      ? 'Bluetooth aktif. Pilih printer yang sudah dipasangkan.'
                      : 'Bluetooth belum aktif. Nyalakan Bluetooth lalu muat ulang.',
                  tone: _bluetoothOn ? StatusTone.success : StatusTone.warning,
                  icon: _bluetoothOn
                      ? Icons.bluetooth_connected_rounded
                      : Icons.bluetooth_disabled_rounded,
                  action: _bluetoothOn
                      ? null
                      : TextButton(
                          onPressed: () => context.push('/settings'),
                          child: const Text('Kembali'),
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
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _config.enabled,
                          title: const Text('Cetak struk otomatis'),
                          subtitle: const Text(
                            'Kirim struk ke printer setelah pembayaran.',
                          ),
                          onChanged: (value) {
                            setState(() {
                              _config = PrinterConfig(
                                enabled: value,
                                name: _config.name,
                                address: _config.address,
                                paperWidth: _config.paperWidth,
                              );
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
                              _config = PrinterConfig(
                                enabled: _config.enabled,
                                name: device?.name ?? _config.name,
                                address: value,
                                paperWidth: _config.paperWidth,
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
                              _config = PrinterConfig(
                                enabled: _config.enabled,
                                name: _config.name,
                                address: _config.address,
                                paperWidth: value,
                              );
                            });
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        FilledButton.icon(
                          onPressed: _busy || !_bluetoothOn ? null : _save,
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
                            _busy ? 'Menyimpan…' : 'Simpan & hubungkan',
                          ),
                        ),
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
