import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:utang_tracker/features/updates/domain/entities/app_update.dart';

typedef DownloadProgress = void Function(double progress);

class UpdateConfig {
  UpdateConfig._();

  static const manifestUrl = String.fromEnvironment(
    'UPDATE_MANIFEST_URL',
    defaultValue:
        'https://github.com/alduanemirasol/utang_tracker/releases/latest/download/update-manifest.json',
  );
  static bool get isEnabled => manifestUrl.trim().isNotEmpty;
}

class AppUpdateService {
  AppUpdateService({HttpClient? httpClient, MethodChannel? channel})
    : _httpClient = httpClient ?? HttpClient(),
      _channel =
          channel ??
          const MethodChannel('com.example.utang_tracker/app_update');

  final HttpClient _httpClient;
  final MethodChannel _channel;

  Future<AppUpdate?> checkForUpdate() async {
    if (!UpdateConfig.isEnabled || !Platform.isAndroid) return null;

    final manifestUri = Uri.tryParse(UpdateConfig.manifestUrl);
    if (manifestUri == null ||
        manifestUri.scheme != 'https' ||
        manifestUri.host.isEmpty) {
      throw const UpdateException('Update URL must use HTTPS.');
    }

    final appInfo = await _getAppInfo();
    final response = await _getFollowingHttpsRedirects(
      manifestUri,
      timeout: const Duration(seconds: 15),
    );
    if (response.statusCode != HttpStatus.ok) {
      await response.drain<void>();
      throw UpdateException('Update check failed (${response.statusCode}).');
    }

    final body = await utf8.decoder.bind(response).join();
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, Object?>) {
      throw const UpdateException('Update manifest is invalid.');
    }

    final update = AppUpdate.fromJson(decoded);
    if (update.packageName != appInfo.packageName) {
      throw const UpdateException('Update package does not match this app.');
    }
    return update.versionCode > appInfo.versionCode ? update : null;
  }

  Future<File> download(
    AppUpdate update, {
    required DownloadProgress onProgress,
  }) async {
    final response = await _getFollowingHttpsRedirects(
      update.apkUri,
      timeout: const Duration(seconds: 20),
    );
    if (response.statusCode != HttpStatus.ok) {
      await response.drain<void>();
      throw UpdateException('Download failed (${response.statusCode}).');
    }

    final directory = Directory(
      '${Directory.systemTemp.path}/utang_tracker_updates',
    );
    await directory.create(recursive: true);
    final file = File(
      '${directory.path}/utang-tracker-${update.versionCode}.apk',
    );
    if (await file.exists()) await file.delete();

    final sink = file.openWrite();
    final expectedBytes = response.contentLength;
    var receivedBytes = 0;
    try {
      await for (final chunk in response) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (expectedBytes > 0) {
          onProgress((receivedBytes / expectedBytes).clamp(0, 1));
        }
      }
      await sink.flush();
    } catch (_) {
      await sink.close();
      if (await file.exists()) await file.delete();
      rethrow;
    }
    await sink.close();

    final digest = await sha256.bind(file.openRead()).first;
    if (digest.toString() != update.sha256) {
      await file.delete();
      throw const UpdateException('Downloaded update failed verification.');
    }

    final isTrusted = await _channel.invokeMethod<bool>('verifyApk', {
      'path': file.path,
    });
    if (isTrusted != true) {
      await file.delete();
      throw const UpdateException('Update signature does not match this app.');
    }
    onProgress(1);
    return file;
  }

  Future<InstallResult> install(File apk) async {
    final canInstall =
        await _channel.invokeMethod<bool>('canInstallPackages') ?? false;
    if (!canInstall) {
      await _channel.invokeMethod<void>('openInstallSettings');
      return InstallResult.permissionRequired;
    }
    await _channel.invokeMethod<void>('installApk', {'path': apk.path});
    return InstallResult.started;
  }

  Future<HttpClientResponse> _getFollowingHttpsRedirects(
    Uri initialUri, {
    required Duration timeout,
  }) async {
    var uri = initialUri;
    for (var redirectCount = 0; redirectCount <= 5; redirectCount++) {
      if (uri.scheme != 'https' || uri.host.isEmpty) {
        throw const UpdateException('Update download must use HTTPS.');
      }

      final request = await _httpClient.getUrl(uri).timeout(timeout);
      request.followRedirects = false;
      final response = await request.close().timeout(timeout);
      if (!response.isRedirect) return response;

      final location = response.headers.value(HttpHeaders.locationHeader);
      await response.drain<void>();
      if (location == null) {
        throw const UpdateException('Update redirect is invalid.');
      }
      uri = uri.resolve(location);
    }
    throw const UpdateException('Too many update redirects.');
  }

  Future<_AppInfo> _getAppInfo() async {
    final value = await _channel.invokeMapMethod<String, Object?>('getAppInfo');
    final packageName = value?['packageName'];
    final versionCode = value?['versionCode'];
    if (packageName is! String || versionCode is! int) {
      throw const UpdateException('Could not read the installed app version.');
    }
    return _AppInfo(packageName: packageName, versionCode: versionCode);
  }
}

enum InstallResult { started, permissionRequired }

class UpdateException implements Exception {
  const UpdateException(this.message);

  final String message;

  @override
  String toString() => message;
}

class _AppInfo {
  const _AppInfo({required this.packageName, required this.versionCode});

  final String packageName;
  final int versionCode;
}
