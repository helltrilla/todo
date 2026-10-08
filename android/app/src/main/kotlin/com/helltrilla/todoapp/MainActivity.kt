package com.helltrilla.todoapp

import android.Manifest
import android.app.Activity
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Base64
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import kotlin.math.max

class MainActivity : FlutterActivity() {
    private val channelName = "com.helltrilla.todoapp/notifications"
    private val notificationChannelId = "todoapp_reminders"
    private val pickImageRequestCode = 2002
    private val handler = Handler(Looper.getMainLooper())
    private val scheduledRunnables = mutableMapOf<String, Runnable>()
    private var methodChannel: MethodChannel? = null
    private var pendingQuickAction: String? = null
    private var isFlutterReadyForQuickActions = false
    private var pendingImageResult: MethodChannel.Result? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        extractQuickAction(intent)?.let { pendingQuickAction = it }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        extractQuickAction(intent)?.let { action ->
            if (isFlutterReadyForQuickActions && methodChannel != null) {
                methodChannel?.invokeMethod("onQuickAction", action)
            } else {
                pendingQuickAction = action
            }
        }
    }

    private fun extractQuickAction(intent: Intent?): String? {
        return when (intent?.action) {
            "com.helltrilla.todoapp.QUICK_ACTION_ADD_TASK" -> "add_task"
            "com.helltrilla.todoapp.QUICK_ACTION_FOCUS" -> "open_focus"
            "com.helltrilla.todoapp.QUICK_ACTION_CALENDAR" -> "open_calendar"
            else -> null
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        ensureNotificationChannel()

        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
        methodChannel = channel
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "consumeInitialQuickAction" -> {
                    isFlutterReadyForQuickActions = true
                    val action = pendingQuickAction
                    pendingQuickAction = null
                    result.success(action)
                }

                "requestPermissions" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                        val granted = ContextCompat.checkSelfPermission(
                            this,
                            Manifest.permission.POST_NOTIFICATIONS
                        ) == PackageManager.PERMISSION_GRANTED
                        if (!granted) {
                            ActivityCompat.requestPermissions(
                                this,
                                arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                                1001
                            )
                        }
                        result.success(true)
                    } else {
                        result.success(true)
                    }
                }

                "scheduleNotification" -> {
                    val id = call.argument<String>("id") ?: ""
                    val title = call.argument<String>("title") ?: "TodoApp"
                    val body = call.argument<String>("body") ?: ""
                    val timestampMs = call.argument<Number>("timestampMs")?.toLong() ?: 0L
                    val delayMs = timestampMs - System.currentTimeMillis()

                    scheduledRunnables.remove(id)?.let { handler.removeCallbacks(it) }

                    if (delayMs > -5000L) {
                        val runnable = Runnable {
                            showNotification(id.hashCode(), title, body)
                            scheduledRunnables.remove(id)
                        }
                        scheduledRunnables[id] = runnable
                        handler.postDelayed(runnable, delayMs.coerceAtLeast(500L))
                    }
                    result.success(null)
                }

                "cancelTaskNotifications" -> {
                    val ids = call.argument<List<String>>("ids") ?: emptyList()
                    val manager =
                        getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                    for (id in ids) {
                        scheduledRunnables.remove(id)?.let { handler.removeCallbacks(it) }
                        manager.cancel(id.hashCode())
                    }
                    result.success(null)
                }

                "cancelAllNotifications" -> {
                    for ((_, runnable) in scheduledRunnables) {
                        handler.removeCallbacks(runnable)
                    }
                    scheduledRunnables.clear()
                    val manager =
                        getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                    manager.cancelAll()
                    result.success(null)
                }

                "pickProfileImage" -> {
                    pendingImageResult = result
                    val pickIntent = Intent(Intent.ACTION_GET_CONTENT).apply {
                        type = "image/*"
                        addCategory(Intent.CATEGORY_OPENABLE)
                    }
                    startActivityForResult(
                        Intent.createChooser(pickIntent, "Выберите фото профиля"),
                        pickImageRequestCode
                    )
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == pickImageRequestCode) {
            val callback = pendingImageResult
            pendingImageResult = null
            if (resultCode == Activity.RESULT_OK && data?.data != null) {
                val base64 = encodeUriToSquareJpegBase64(data.data!!)
                callback?.success(base64)
            } else {
                callback?.success(null)
            }
        }
    }

    private fun encodeUriToSquareJpegBase64(uri: Uri): String? {
        return try {
            contentResolver.openInputStream(uri)?.use { stream ->
                val original = BitmapFactory.decodeStream(stream) ?: return null
                val targetSize = 320
                val scale = max(
                    targetSize.toFloat() / original.width.toFloat(),
                    targetSize.toFloat() / original.height.toFloat()
                )
                val scaledW = (original.width * scale).toInt().coerceAtLeast(targetSize)
                val scaledH = (original.height * scale).toInt().coerceAtLeast(targetSize)
                val scaled = Bitmap.createScaledBitmap(original, scaledW, scaledH, true)
                val cropX = ((scaledW - targetSize) / 2).coerceAtLeast(0)
                val cropY = ((scaledH - targetSize) / 2).coerceAtLeast(0)
                val cropped = Bitmap.createBitmap(scaled, cropX, cropY, targetSize, targetSize)
                val out = ByteArrayOutputStream()
                cropped.compress(Bitmap.CompressFormat.JPEG, 82, out)
                Base64.encodeToString(out.toByteArray(), Base64.NO_WRAP)
            }
        } catch (_: Exception) {
            null
        }
    }

    private fun ensureNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                notificationChannelId,
                "Напоминания о задачах",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Уведомления о предстоящих и текущих задачах TodoApp"
            }
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.createNotificationChannel(channel)
        }
    }

    private fun showNotification(notificationId: Int, title: String, body: String) {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val notification = NotificationCompat.Builder(this, notificationChannelId)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .build()
        manager.notify(notificationId, notification)
    }
}
