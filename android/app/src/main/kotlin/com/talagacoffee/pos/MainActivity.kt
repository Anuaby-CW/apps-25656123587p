package com.talagacoffee.pos

import android.Manifest
import android.content.ContentValues
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val channelName = "com.talagacoffee.pos/downloads"
    private val bluetoothPermissionsChannelName =
        "com.talagacoffee.pos/bluetooth_permissions"
    private val storagePermissionRequest = 4102
    private val bluetoothPermissionRequest = 4103
    private var pendingCall: MethodCall? = null
    private var pendingResult: MethodChannel.Result? = null
    private var pendingBluetoothResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                if (call.method != "saveToDownloads") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                if (
                    Build.VERSION.SDK_INT <= Build.VERSION_CODES.P &&
                    checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) !=
                        PackageManager.PERMISSION_GRANTED
                ) {
                    pendingCall = call
                    pendingResult = result
                    requestPermissions(
                        arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE),
                        storagePermissionRequest,
                    )
                    return@setMethodCallHandler
                }
                saveToDownloads(call, result)
            }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            bluetoothPermissionsChannelName,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "status" -> result.success(bluetoothPermissionStatus())
                "request" -> requestBluetoothPermissions(result)
                "openAppSettings" -> {
                    val intent = Intent(
                        Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                        Uri.parse("package:$packageName"),
                    )
                    startActivity(intent)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == bluetoothPermissionRequest) {
            val result = pendingBluetoothResult
            pendingBluetoothResult = null
            result?.success(bluetoothPermissionStatus())
            return
        }
        if (requestCode != storagePermissionRequest) return

        val call = pendingCall
        val result = pendingResult
        pendingCall = null
        pendingResult = null
        if (call == null || result == null) return

        if (grantResults.firstOrNull() == PackageManager.PERMISSION_GRANTED) {
            saveToDownloads(call, result)
        } else {
            result.error(
                "STORAGE_PERMISSION_DENIED",
                "Izin penyimpanan diperlukan untuk mengekspor PDF.",
                null,
            )
        }
    }

    private fun requestBluetoothPermissions(result: MethodChannel.Result) {
        val missing = missingBluetoothPermissions()
        if (missing.isEmpty()) {
            result.success("granted")
            return
        }
        if (pendingBluetoothResult != null) {
            result.error(
                "PERMISSION_REQUEST_ACTIVE",
                "Permintaan izin Bluetooth sedang berlangsung.",
                null,
            )
            return
        }
        getSharedPreferences("runtime_permissions", MODE_PRIVATE)
            .edit()
            .putBoolean("bluetooth_requested", true)
            .apply()
        pendingBluetoothResult = result
        requestPermissions(missing.toTypedArray(), bluetoothPermissionRequest)
    }

    private fun bluetoothPermissionStatus(): String {
        val missing = missingBluetoothPermissions()
        if (missing.isEmpty()) return "granted"

        val requested = getSharedPreferences("runtime_permissions", MODE_PRIVATE)
            .getBoolean("bluetooth_requested", false)
        val permanentlyDenied = requested && missing.any { permission ->
            !shouldShowRequestPermissionRationale(permission)
        }
        return if (permanentlyDenied) "permanentlyDenied" else "denied"
    }

    private fun missingBluetoothPermissions(): List<String> {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) return emptyList()
        return requiredBluetoothPermissions().filter { permission ->
            checkSelfPermission(permission) != PackageManager.PERMISSION_GRANTED
        }
    }

    private fun requiredBluetoothPermissions(): List<String> {
        val permissions = mutableListOf(
            Manifest.permission.ACCESS_COARSE_LOCATION,
            Manifest.permission.ACCESS_FINE_LOCATION,
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            permissions += Manifest.permission.BLUETOOTH_CONNECT
            permissions += Manifest.permission.BLUETOOTH_SCAN
        }
        return permissions
    }

    private fun saveToDownloads(call: MethodCall, result: MethodChannel.Result) {
        val fileName = call.argument<String>("fileName")
        val mimeType = call.argument<String>("mimeType") ?: "application/pdf"
        val bytes = call.argument<ByteArray>("bytes")
        if (fileName.isNullOrBlank() || bytes == null) {
            result.error("INVALID_ARGUMENTS", "Nama file atau data PDF tidak valid.", null)
            return
        }

        try {
            val location = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                saveWithMediaStore(fileName, mimeType, bytes)
            } else {
                saveLegacy(fileName, bytes)
            }
            result.success(location)
        } catch (error: Exception) {
            result.error("SAVE_FAILED", error.message ?: "PDF gagal disimpan.", null)
        }
    }

    private fun saveWithMediaStore(
        fileName: String,
        mimeType: String,
        bytes: ByteArray,
    ): String {
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
            put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
            put(
                MediaStore.MediaColumns.RELATIVE_PATH,
                "${Environment.DIRECTORY_DOWNLOADS}/Talaga Coffee",
            )
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }
        val uri = contentResolver.insert(
            MediaStore.Downloads.EXTERNAL_CONTENT_URI,
            values,
        ) ?: error("Folder Downloads tidak tersedia.")

        try {
            contentResolver.openOutputStream(uri)?.use { stream ->
                stream.write(bytes)
                stream.flush()
            } ?: error("File PDF tidak dapat dibuka untuk ditulis.")
            values.clear()
            values.put(MediaStore.MediaColumns.IS_PENDING, 0)
            contentResolver.update(uri, values, null, null)
            return uri.toString()
        } catch (error: Exception) {
            contentResolver.delete(uri, null, null)
            throw error
        }
    }

    @Suppress("DEPRECATION")
    private fun saveLegacy(fileName: String, bytes: ByteArray): String {
        val downloads = Environment.getExternalStoragePublicDirectory(
            Environment.DIRECTORY_DOWNLOADS,
        )
        val directory = File(downloads, "Talaga Coffee")
        if (!directory.exists() && !directory.mkdirs()) {
            error("Folder Downloads/Talaga Coffee tidak dapat dibuat.")
        }
        val file = File(directory, fileName)
        FileOutputStream(file).use { stream ->
            stream.write(bytes)
            stream.flush()
        }
        return file.absolutePath
    }
}
