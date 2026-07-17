package com.example.utang_tracker

import android.content.Intent
import android.content.pm.PackageInfo
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.security.MessageDigest

class MainActivity : FlutterActivity() {
    private val channelName = "com.example.utang_tracker/app_update"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "getAppInfo" -> result.success(getAppInfo())
                        "verifyApk" -> {
                            val path = call.argument<String>("path")
                                ?: error("Missing APK path")
                            result.success(verifyApk(File(path)))
                        }
                        "canInstallPackages" -> result.success(canInstallPackages())
                        "openInstallSettings" -> {
                            openInstallSettings()
                            result.success(null)
                        }
                        "installApk" -> {
                            val path = call.argument<String>("path")
                                ?: error("Missing APK path")
                            installApk(File(path))
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                } catch (error: Exception) {
                    result.error("APP_UPDATE_ERROR", error.message, null)
                }
            }
    }

    private fun getAppInfo(): Map<String, Any> {
        val info = packageManager.getPackageInfo(packageName, 0)
        return mapOf(
            "packageName" to packageName,
            "versionName" to (info.versionName ?: ""),
            "versionCode" to versionCode(info),
        )
    }

    private fun verifyApk(file: File): Boolean {
        if (!file.isFile) return false

        val archive = packageInfo(file.absolutePath, PackageManager.GET_SIGNING_CERTIFICATES)
            ?: return false
        if (archive.packageName != packageName) return false

        val installed = packageInfo(packageName, PackageManager.GET_SIGNING_CERTIFICATES)
            ?: return false
        val archiveSigners = signerDigests(archive)
        val installedSigners = signerDigests(installed)
        return archiveSigners.intersect(installedSigners).isNotEmpty()
    }

    @Suppress("DEPRECATION")
    private fun packageInfo(source: String, flags: Int): PackageInfo? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (source == packageName) {
                packageManager.getPackageInfo(source, PackageManager.PackageInfoFlags.of(flags.toLong()))
            } else {
                packageManager.getPackageArchiveInfo(source, PackageManager.PackageInfoFlags.of(flags.toLong()))
            }
        } else if (source == packageName) {
            packageManager.getPackageInfo(source, flags)
        } else {
            packageManager.getPackageArchiveInfo(source, flags)
        }

    @Suppress("DEPRECATION")
    private fun signerDigests(info: PackageInfo): Set<String> {
        val signatures = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            val signingInfo = info.signingInfo ?: return emptySet()
            if (signingInfo.hasMultipleSigners()) {
                signingInfo.apkContentsSigners
            } else {
                signingInfo.signingCertificateHistory
            }
        } else {
            info.signatures ?: emptyArray()
        }
        return signatures.map { signature ->
            MessageDigest.getInstance("SHA-256")
                .digest(signature.toByteArray())
                .joinToString("") { "%02x".format(it) }
        }.toSet()
    }

    @Suppress("DEPRECATION")
    private fun versionCode(info: PackageInfo): Long =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            info.longVersionCode
        } else {
            info.versionCode.toLong()
        }

    private fun canInstallPackages(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.O || packageManager.canRequestPackageInstalls()

    private fun openInstallSettings() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        startActivity(
            Intent(
                Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                Uri.parse("package:$packageName"),
            ),
        )
    }

    private fun installApk(file: File) {
        check(file.isFile) { "Downloaded APK was not found" }
        check(canInstallPackages()) { "Install permission is required" }

        val uri = FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
        startActivity(
            Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, "application/vnd.android.package-archive")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            },
        )
    }
}
