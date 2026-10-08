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
import android.media.AudioAttributes
import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Base64
import android.view.KeyEvent
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import kotlin.math.PI
import kotlin.math.max
import kotlin.math.sin
import kotlin.random.Random

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
    @Volatile private var ambientSoundMode: String = "off"
    @Volatile private var ambientVolume: Float = 0.45f
    private var ambientThread: Thread? = null

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

                "setAmbientSound" -> {
                    val sound = call.argument<String>("sound") ?: "off"
                    val volume = call.argument<Number>("volume")?.toFloat() ?: 0.45f
                    configureAmbientAudio(sound, volume)
                    result.success(null)
                }

                "openExternalUrl" -> {
                    val rawUrl = call.argument<String>("url") ?: ""
                    val fallbackUrl = call.argument<String>("fallbackUrl")
                    val opened = launchUriWithFallback(rawUrl, fallbackUrl)
                    result.success(opened)
                }

                "sendMediaCommand" -> {
                    val command = call.argument<String>("command") ?: "playPause"
                    dispatchSystemMediaKey(command)
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun launchUriWithFallback(rawUrl: String, fallbackUrl: String?): Boolean {
        try {
            val primaryIntent = Intent(Intent.ACTION_VIEW, Uri.parse(rawUrl)).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(primaryIntent)
            return true
        } catch (_: Exception) {
            if (!fallbackUrl.isNullOrBlank()) {
                return try {
                    val fbIntent = Intent(Intent.ACTION_VIEW, Uri.parse(fallbackUrl)).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    startActivity(fbIntent)
                    true
                } catch (_: Exception) {
                    false
                }
            }
            return false
        }
    }

    private fun dispatchSystemMediaKey(command: String) {
        val keyCode = when (command) {
            "previous" -> KeyEvent.KEYCODE_MEDIA_PREVIOUS
            "next" -> KeyEvent.KEYCODE_MEDIA_NEXT
            else -> KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE
        }
        val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        audioManager.dispatchMediaKeyEvent(KeyEvent(KeyEvent.ACTION_DOWN, keyCode))
        audioManager.dispatchMediaKeyEvent(KeyEvent(KeyEvent.ACTION_UP, keyCode))
    }

    private fun configureAmbientAudio(sound: String, volume: Float) {
        ambientSoundMode = sound
        ambientVolume = volume.coerceIn(0f, 1f)
        if (sound == "off" || ambientVolume <= 0.001f) {
            ambientThread = null
            return
        }
        if (ambientThread?.isAlive == true) return

        val worker = Thread {
            val sampleRate = 22050
            val minBuf = AudioTrack.getMinBufferSize(
                sampleRate,
                AudioFormat.CHANNEL_OUT_MONO,
                AudioFormat.ENCODING_PCM_16BIT
            ).coerceAtLeast(2048)

            val track = AudioTrack.Builder()
                .setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_MEDIA)
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .build()
                )
                .setAudioFormat(
                    AudioFormat.Builder()
                        .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                        .setSampleRate(sampleRate)
                        .setChannelMask(AudioFormat.CHANNEL_OUT_MONO)
                        .build()
                )
                .setBufferSizeInBytes(minBuf)
                .build()

            val buffer = ShortArray(1024)
            var filterState = 0f
            var secondaryState = 0f
            var lfoPhase = 0.0

            try {
                track.play()
                while (ambientSoundMode != "off" && ambientVolume > 0.001f) {
                    val mode = ambientSoundMode
                    val gain = ambientVolume * 0.22f
                    for (i in buffer.indices) {
                        val white = Random.nextFloat() * 2f - 1f
                        val sample: Float = when (mode) {
                            "rain" -> {
                                filterState = 0.90f * filterState + 0.10f * white
                                secondaryState = 0.72f * secondaryState + 0.28f * (white - filterState)
                                (filterState * 0.65f + secondaryState * 0.35f) * gain
                            }
                            "waves" -> {
                                lfoPhase += (2.0 * PI * 0.13) / sampleRate
                                if (lfoPhase > 2.0 * PI) lfoPhase -= 2.0 * PI
                                val swell = (0.30 + 0.70 * (0.5 * (1.0 + sin(lfoPhase)))).toFloat()
                                filterState = 0.965f * filterState + 0.035f * white
                                filterState * swell * gain * 1.35f
                            }
                            "cafe" -> {
                                filterState = (filterState + 0.025f * white) / 1.025f
                                filterState * gain * 2.2f
                            }
                            "vinyl" -> {
                                filterState = 0.94f * filterState + 0.06f * white
                                val crackle = if (Random.nextFloat() > 0.9985f) (Random.nextFloat() * 0.9f - 0.45f) else 0f
                                (filterState * 0.75f + crackle * 0.25f) * gain
                            }
                            else -> 0f
                        }
                        buffer[i] = (sample.coerceIn(-1f, 1f) * Short.MAX_VALUE).toInt().toShort()
                    }
                    track.write(buffer, 0, buffer.size)
                }
            } catch (_: Exception) {
            } finally {
                try {
                    track.stop()
                    track.release()
                } catch (_: Exception) {}
            }
        }
        worker.isDaemon = true
        ambientThread = worker
        worker.start()
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
