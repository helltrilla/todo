package com.helltrilla.todoapp

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.helltrilla.todoapp/notifications"
    private val notificationChannelId = "todoapp_reminders"
    private val handler = Handler(Looper.getMainLooper())
    private val scheduledRunnables = mutableMapOf<String, Runnable>()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        ensureNotificationChannel()

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
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

                    else -> result.notImplemented()
                }
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
