package com.example.motaz_app_flutter

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val notificationChannel = "fastika/notifications"
    private val exportFilesChannel = "fastika/export_files"
    private val followUpChannelId = "follow_up_tasks"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            notificationChannel
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "initialize" -> {
                    createFollowUpNotificationChannel()
                    requestNotificationPermissionIfNeeded()
                    result.success(null)
                }

                "show" -> {
                    val id = call.argument<Int>("id") ?: 4100
                    val title = call.argument<String>("title") ?: "Fastika"
                    val body = call.argument<String>("body") ?: ""
                    showFollowUpNotification(id, title, body)
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            exportFilesChannel
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "ensureDirectory" -> {
                    val folderName = call.argument<String>("folderName") ?: "reports"
                    try {
                        ensurePublicFolder(folderName)
                        result.success(publicDisplayPath(folderName, ""))
                    } catch (error: Exception) {
                        result.error("EXPORT_DIRECTORY_FAILED", error.message, null)
                    }
                }

                "saveFile" -> {
                    val folderName = call.argument<String>("folderName") ?: "reports"
                    val fileName = call.argument<String>("fileName") ?: "export"
                    val mimeType = call.argument<String>("mimeType") ?: "application/octet-stream"
                    val bytes = call.argument<ByteArray>("bytes") ?: ByteArray(0)
                    try {
                        val savedPath = savePublicFile(folderName, fileName, mimeType, bytes)
                        result.success(savedPath)
                    } catch (error: Exception) {
                        result.error("EXPORT_FILE_FAILED", error.message, null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun ensurePublicFolder(folderName: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val markerName = ".fastika_keep"
            val relativePath = publicRelativePath(folderName)
            if (!mediaStoreFileExists(relativePath, markerName)) {
                savePublicFile(folderName, markerName, "text/plain", ByteArray(0))
            }
            return
        }

        val folder = File(
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOCUMENTS),
            "Fastika/$folderName"
        )
        if (!folder.exists() && !folder.mkdirs()) {
            throw IllegalStateException("Could not create ${folder.absolutePath}")
        }
    }

    private fun savePublicFile(
        folderName: String,
        fileName: String,
        mimeType: String,
        bytes: ByteArray
    ): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val relativePath = publicRelativePath(folderName)
            val values = ContentValues().apply {
                put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
                put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
                put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath)
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }
            val resolver = applicationContext.contentResolver
            val collection = MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
            val uri = resolver.insert(collection, values)
                ?: throw IllegalStateException("Could not create $fileName")

            resolver.openOutputStream(uri)?.use { output ->
                output.write(bytes)
                output.flush()
            } ?: throw IllegalStateException("Could not open $fileName")

            values.clear()
            values.put(MediaStore.MediaColumns.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
            return publicDisplayPath(folderName, fileName)
        }

        val folder = File(
            Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOCUMENTS),
            "Fastika/$folderName"
        )
        if (!folder.exists() && !folder.mkdirs()) {
            throw IllegalStateException("Could not create ${folder.absolutePath}")
        }
        val target = File(folder, fileName)
        target.writeBytes(bytes)
        return target.absolutePath
    }

    private fun mediaStoreFileExists(relativePath: String, fileName: String): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return false
        val collection: Uri = MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        val projection = arrayOf(MediaStore.MediaColumns._ID)
        val selection =
            "${MediaStore.MediaColumns.DISPLAY_NAME}=? AND ${MediaStore.MediaColumns.RELATIVE_PATH}=?"
        val args = arrayOf(fileName, relativePath)
        applicationContext.contentResolver.query(
            collection,
            projection,
            selection,
            args,
            null
        )?.use { cursor ->
            return cursor.moveToFirst()
        }
        return false
    }

    private fun publicRelativePath(folderName: String): String {
        return "${Environment.DIRECTORY_DOCUMENTS}/Fastika/$folderName/"
    }

    private fun publicDisplayPath(folderName: String, fileName: String): String {
        val suffix = if (fileName.isEmpty()) "" else "/$fileName"
        return "Documents/Fastika/$folderName$suffix"
    }

    private fun createFollowUpNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val channel = NotificationChannel(
            followUpChannelId,
            "مهام المتابعة",
            NotificationManager.IMPORTANCE_HIGH
        ).apply {
            description = "تنبيهات العملاء والمبالغ والصلاحيات"
        }
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.createNotificationChannel(channel)
    }

    private fun requestNotificationPermissionIfNeeded() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) return
        if (checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
        ) {
            return
        }
        requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 4100)
    }

    private fun showFollowUpNotification(id: Int, title: String, body: String) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED
        ) {
            return
        }

        val launchIntent =
            packageManager.getLaunchIntentForPackage(packageName) ?: Intent(this, MainActivity::class.java)
        launchIntent.flags = Intent.FLAG_ACTIVITY_CLEAR_TOP or Intent.FLAG_ACTIVITY_SINGLE_TOP

        val immutableFlag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_IMMUTABLE
        } else {
            0
        }
        val pendingIntentFlags = PendingIntent.FLAG_UPDATE_CURRENT or immutableFlag
        val pendingIntent = PendingIntent.getActivity(this, 0, launchIntent, pendingIntentFlags)

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, followUpChannelId)
        } else {
            Notification.Builder(this)
        }

        val notification = builder
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
            .setPriority(Notification.PRIORITY_HIGH)
            .build()

        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.notify(id, notification)
    }
}
