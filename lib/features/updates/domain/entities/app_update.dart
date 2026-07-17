class AppUpdate {
  const AppUpdate({
    required this.versionCode,
    required this.versionName,
    required this.packageName,
    required this.apkUri,
    required this.sha256,
    required this.releaseNotes,
    required this.isRequired,
  });

  factory AppUpdate.fromJson(Map<String, Object?> json) {
    final versionCode = json['versionCode'];
    final versionName = json['versionName'];
    final packageName = json['packageName'];
    final apkUrl = json['apkUrl'];
    final sha256 = json['sha256'];
    final releaseNotes = json['releaseNotes'];
    final isRequired = json['required'];

    if (versionCode is! int || versionCode <= 0) {
      throw const FormatException('versionCode must be a positive integer');
    }
    if (versionName is! String || versionName.trim().isEmpty) {
      throw const FormatException('versionName is required');
    }
    if (packageName is! String || packageName.trim().isEmpty) {
      throw const FormatException('packageName is required');
    }
    if (apkUrl is! String) {
      throw const FormatException('apkUrl is required');
    }
    final apkUri = Uri.tryParse(apkUrl);
    if (apkUri == null || apkUri.scheme != 'https' || apkUri.host.isEmpty) {
      throw const FormatException('apkUrl must use HTTPS');
    }
    if (sha256 is! String || !RegExp(r'^[a-fA-F0-9]{64}$').hasMatch(sha256)) {
      throw const FormatException('sha256 must be a 64-character hex digest');
    }
    if (releaseNotes != null && releaseNotes is! String) {
      throw const FormatException('releaseNotes must be text');
    }
    if (isRequired != null && isRequired is! bool) {
      throw const FormatException('required must be true or false');
    }

    return AppUpdate(
      versionCode: versionCode,
      versionName: versionName.trim(),
      packageName: packageName.trim(),
      apkUri: apkUri,
      sha256: sha256.toLowerCase(),
      releaseNotes: (releaseNotes as String?)?.trim() ?? '',
      isRequired: (isRequired as bool?) ?? false,
    );
  }

  final int versionCode;
  final String versionName;
  final String packageName;
  final Uri apkUri;
  final String sha256;
  final String releaseNotes;
  final bool isRequired;
}
