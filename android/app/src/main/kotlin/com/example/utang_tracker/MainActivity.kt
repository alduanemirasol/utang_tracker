package com.example.utang_tracker

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {

    private val channel = "com.example.utang_tracker/updater"
    private val backupChannel = "com.example.utang_tracker/backup_files"
    private val createBackupRequest = 8401
    private val pickBackupRequest = 8402
    private var pendingBackupResult: MethodChannel.Result? = null
    private var pendingBackupSource: File? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channel,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getSupportedAbis" -> {
                    result.success(Build.SUPPORTED_ABIS.toList())
                }

                "canInstallUnknownApps" -> {
                    val can = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        packageManager.canRequestPackageInstalls()
                    } else {
                        true
                    }
                    result.success(can)
                }

                "openInstallSettings" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        val intent = Intent(
                            Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                            Uri.parse("package:$packageName"),
                        )
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        result.success(null)
                    } else {
                        result.success(null)
                    }
                }

                "installApk" -> {
                    val path = call.argument<String>("path")
                    if (path == null) {
                        result.error("INVALID_ARGUMENT", "path is required", null)
                        return@setMethodCallHandler
                    }
                    val file = File(path)
                    if (!file.exists()) {
                        result.error("FILE_NOT_FOUND", "APK file not found at $path", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val uri = FileProvider.getUriForFile(
                            this,
                            "$packageName.fileprovider",
                            file,
                        )
                        val intent = Intent(Intent.ACTION_VIEW).apply {
                            setDataAndType(uri, "application/vnd.android.package-archive")
                            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("INSTALL_FAILED", e.message, null)
                    }
                }

                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            backupChannel,
        ).setMethodCallHandler { call, result ->
            if (pendingBackupResult != null) {
                result.error("BUSY", "Another backup file operation is active", null)
                return@setMethodCallHandler
            }
            when (call.method) {
                "saveBackup" -> {
                    val sourcePath = call.argument<String>("sourcePath")
                    val fileName = call.argument<String>("fileName")
                    val source = sourcePath?.let(::File)
                    if (source == null || !source.exists() || fileName.isNullOrBlank()) {
                        result.error("INVALID_ARGUMENT", "A valid sourcePath and fileName are required", null)
                        return@setMethodCallHandler
                    }
                    pendingBackupResult = result
                    pendingBackupSource = source
                    val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = "application/vnd.sqlite3"
                        putExtra(Intent.EXTRA_TITLE, fileName)
                    }
                    startActivityForResult(intent, createBackupRequest)
                }

                "pickBackup" -> {
                    pendingBackupResult = result
                    val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = "*/*"
                        putExtra(
                            Intent.EXTRA_MIME_TYPES,
                            arrayOf("application/vnd.sqlite3", "application/x-sqlite3", "application/octet-stream"),
                        )
                    }
                    startActivityForResult(intent, pickBackupRequest)
                }

                else -> result.notImplemented()
            }
        }
    }

    @Deprecated("Deprecated in Android")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != createBackupRequest && requestCode != pickBackupRequest) return
        val result = pendingBackupResult ?: return
        pendingBackupResult = null
        try {
            if (resultCode != RESULT_OK || data?.data == null) {
                pendingBackupSource = null
                result.success(if (requestCode == createBackupRequest) false else null)
                return
            }
            val uri = data.data!!
            if (requestCode == createBackupRequest) {
                val source = pendingBackupSource
                    ?: throw IllegalStateException("Backup source is missing")
                contentResolver.openOutputStream(uri, "w").use { output ->
                    requireNotNull(output) { "Could not open the selected destination" }
                    source.inputStream().use { input -> input.copyTo(output) }
                }
                pendingBackupSource = null
                result.success(true)
            } else {
                val destination = File(cacheDir, "utang-restore-${System.currentTimeMillis()}.sqlite")
                contentResolver.openInputStream(uri).use { input ->
                    requireNotNull(input) { "Could not read the selected backup" }
                    destination.outputStream().use { output -> input.copyTo(output) }
                }
                result.success(destination.absolutePath)
            }
        } catch (error: Exception) {
            pendingBackupSource = null
            result.error("FILE_OPERATION_FAILED", error.message, null)
        }
    }
}
