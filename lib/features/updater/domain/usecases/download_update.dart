import 'package:utang_tracker/features/updater/domain/entities/app_release.dart';
import 'package:utang_tracker/features/updater/domain/repositories/update_repository.dart';

class DownloadUpdate {
  const DownloadUpdate(this._repo);

  final UpdateRepository _repo;

  Future<String> call(
    ReleaseAsset asset,
    void Function(double progress) onProgress,
  ) async {
    await _repo.cleanupOldApks();
    return _repo.downloadApk(asset, onProgress);
  }
}
