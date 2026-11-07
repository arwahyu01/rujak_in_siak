import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/app_uuid.dart';

class ProofImageService {
  ProofImageService({
    ImagePicker? picker,
    Future<Directory> Function()? supportDirectory,
  }) : _picker = picker ?? ImagePicker(),
       _supportDirectory = supportDirectory ?? getApplicationSupportDirectory;

  static const _folder = 'payment_proofs';
  static const _knownExtensions = {'.jpg', '.jpeg', '.png', '.webp'};

  final ImagePicker _picker;
  final Future<Directory> Function() _supportDirectory;

  Future<String?> pick(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 70,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (picked == null) return null;

      final directory = await _directory();
      final extension = p.extension(picked.path).toLowerCase();
      final safeExtension = _knownExtensions.contains(extension)
          ? extension
          : '.jpg';
      final target = File(
        p.join(directory.path, 'proof_${newUuid()}$safeExtension'),
      );
      await File(picked.path).copy(target.path);
      return target.path;
    } catch (error) {
      throw AppException(
        'PROOF_CAPTURE_FAILED',
        'Foto bukti tidak dapat disiapkan. Coba lagi atau pilih dari galeri.',
        details: {'error': error.toString()},
      );
    }
  }

  Future<void> delete(String? path) async {
    if (path == null || path.isEmpty) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // Cleanup must never block checkout or upload.
    }
  }

  Future<void> sweepOrphans(Set<String> referencedPaths) async {
    try {
      final directory = await _directory();
      if (!await directory.exists()) return;
      final cutoff = DateTime.now().subtract(const Duration(hours: 24));
      await for (final entry in directory.list()) {
        if (entry is! File || referencedPaths.contains(entry.path)) continue;
        final stat = await entry.stat();
        if (stat.modified.isBefore(cutoff)) {
          await entry.delete();
        }
      }
    } catch (_) {
      // Orphan cleanup is best-effort.
    }
  }

  Future<Directory> _directory() async {
    final root = await _supportDirectory();
    final directory = Directory(p.join(root.path, _folder));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }
}
