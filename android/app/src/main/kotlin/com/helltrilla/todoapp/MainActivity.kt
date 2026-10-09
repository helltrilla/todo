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

                "getMediaPlaybackState" -> {
                    val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                    result.success(audioManager.isMusicActive)
                }

                "getSystemVolume" -> {
                    val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                    val current = audioManager.getStreamVolume(AudioManager.STREAM_MUSIC)
                    val max = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC).coerceAtLeast(1)
                    result.success(current.toDouble() / max.toDouble())
                }

                "setSystemVolume" -> {
                    val volume = (call.argument<Number>("volume")?.toDouble() ?: 0.65).coerceIn(0.0, 1.0)
                    val audioManager = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                    val max = audioManager.getStreamMaxVolume(AudioManager.STREAM_MUSIC).coerceAtLeast(1)
                    val target = Math.round(volume * max).toInt().coerceIn(0, max)
                    audioManager.setStreamVolume(AudioManager.STREAM_MUSIC, target, 0)
                    result.success(null)
                }

                "shareFile" -> {
                    val fileName = call.argument<String>("fileName") ?: "todoapp_export.json"
                    val content = call.argument<String>("content") ?: ""
                    try {
                        val shareIntent = Intent(Intent.ACTION_SEND).apply {
                            type = "text/plain"
                            putExtra(Intent.EXTRA_SUBJECT, fileName)
                            putExtra(Intent.EXTRA_TEXT, content)
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(Intent.createChooser(shareIntent, "Поделиться экспортом"))
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("SHARE_ERROR", e.localizedMessage, null)
                    }
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
            var lfoPhase2 = 0.0
            var drop1Env = 0f
            var drop1Phase = 0.0
            var drop1Freq = 1100.0
            var drop2Env = 0f
            var drop2Phase = 0.0
            var drop2Freq = 1900.0
            var chord1 = 0.0
            var chord2 = 0.0
            var chord3 = 0.0
            var chord4 = 0.0
            var clinkEnv = 0f
            var clinkPhase = 0.0
            var clinkFreq = 2400.0
            var vinylPopEnv = 0f
            var vinylPopPhase = 0.0
            var vinylPopFreq = 2100.0
            var vinylCrackleEnv = 0f
            var fireRoarState = 0f
            var fireSnapEnv = 0f
            var fireSnapFreq = 1600.0
            var fireSnapPhase = 0.0
            var fireCrackleEnv = 0f
            var pinkB0 = 0f
            var pinkB1 = 0f
            var pinkB2 = 0f
            val twoPi = 2.0 * PI

            try {
                track.play()
                while (ambientSoundMode != "off" && ambientVolume > 0.001f) {
                    val mode = ambientSoundMode
                    val gain = ambientVolume * 0.28f
                    for (i in buffer.indices) {
                        val white = Random.nextFloat() * 2f - 1f
                        val sample: Float = when (mode) {
                            "rain" -> {
                                filterState = 0.86f * filterState + 0.14f * white
                                val showerBed = (white - filterState) * 0.18f + filterState * 0.22f
                                if (drop1Env < 0.001f && Random.nextFloat() > 0.9989f) {
                                    drop1Env = 0.55f + Random.nextFloat() * 0.45f
                                    drop1Freq = 680.0 + Random.nextDouble() * 670.0
                                    drop1Phase = 0.0
                                }
                                if (drop2Env < 0.001f && Random.nextFloat() > 0.9987f) {
                                    drop2Env = 0.45f + Random.nextFloat() * 0.45f
                                    drop2Freq = 1550.0 + Random.nextDouble() * 1100.0
                                    drop2Phase = 0.0
                                }
                                var drops = 0f
                                if (drop1Env > 0.001f) {
                                    drop1Freq *= 1.0005
                                    drop1Phase += (twoPi * drop1Freq) / sampleRate
                                    drops += (sin(drop1Phase).toFloat()) * drop1Env * 0.55f
                                    drop1Env *= 0.992f
                                }
                                if (drop2Env > 0.001f) {
                                    drop2Freq *= 1.00035
                                    drop2Phase += (twoPi * drop2Freq) / sampleRate
                                    drops += (sin(drop2Phase).toFloat()) * drop2Env * 0.42f
                                    drop2Env *= 0.989f
                                }
                                (showerBed + drops) * gain
                            }
                            "fire" -> {
                                fireRoarState = 0.985f * fireRoarState + 0.015f * white
                                lfoPhase += (twoPi * 1.8) / sampleRate
                                if (lfoPhase > twoPi) lfoPhase -= twoPi
                                val flameTurbulence = (0.75 + 0.25 * sin(lfoPhase)).toFloat()
                                val roar = fireRoarState * flameTurbulence * 2.2f

                                val hiss = (white - (0.70f * filterState + 0.30f * white)) * 0.12f

                                if (fireSnapEnv < 0.001f && Random.nextFloat() > 0.9992f) {
                                    fireSnapEnv = 0.55f + Random.nextFloat() * 0.45f
                                    fireSnapFreq = 1100.0 + Random.nextDouble() * 1700.0
                                    fireSnapPhase = 0.0
                                }
                                var snap = 0f
                                if (fireSnapEnv > 0.001f) {
                                    fireSnapPhase += (twoPi * fireSnapFreq) / sampleRate
                                    snap = (sin(fireSnapPhase).toFloat()) * fireSnapEnv * 0.85f
                                    fireSnapEnv *= 0.988f
                                }

                                if (fireCrackleEnv < 0.01f && Random.nextFloat() > 0.9975f) {
                                    fireCrackleEnv = 0.25f + Random.nextFloat() * 0.45f
                                }
                                var crackle = 0f
                                if (fireCrackleEnv > 0.01f) {
                                    crackle = white * fireCrackleEnv * 0.45f
                                    fireCrackleEnv *= 0.92f
                                }

                                (roar + hiss + snap + crackle) * gain * 1.35f
                            }
                            "noise" -> {
                                pinkB0 = 0.99886f * pinkB0 + white * 0.0555179f
                                pinkB1 = 0.99332f * pinkB1 + white * 0.0750759f
                                pinkB2 = 0.96900f * pinkB2 + white * 0.1538520f
                                val pink = pinkB0 + pinkB1 + pinkB2 + white * 0.5362f
                                pink * 0.16f * gain * 1.4f
                            }
                            "waves" -> {
                                lfoPhase += (twoPi * 0.105) / sampleRate
                                if (lfoPhase > twoPi) lfoPhase -= twoPi
                                lfoPhase2 += (twoPi * 0.037) / sampleRate
                                if (lfoPhase2 > twoPi) lfoPhase2 -= twoPi
                                val rawWave = 0.5 * (1.0 + sin(lfoPhase + 0.35 * sin(lfoPhase2)))
                                val waveCrest = Math.pow(rawWave, 2.8).toFloat()
                                val cutoff = 0.008f + 0.35f * waveCrest
                                filterState = (1f - cutoff) * filterState + cutoff * white
                                secondaryState = 0.992f * secondaryState + 0.008f * white
                                val surf = filterState * (0.06f + 0.94f * waveCrest) + secondaryState * 0.45f
                                surf * gain * 1.45f
                            }
                            "cafe" -> {
                                lfoPhase += (twoPi * 0.22) / sampleRate
                                if (lfoPhase > twoPi) lfoPhase -= twoPi
                                val vibrato = 1.0 + 0.0018 * sin(lfoPhase)
                                val breathe = (0.72 + 0.28 * sin(lfoPhase * 0.5)).toFloat()
                                chord1 += (twoPi * 146.83 * vibrato) / sampleRate
                                chord2 += (twoPi * 174.61 * vibrato) / sampleRate
                                chord3 += (twoPi * 220.00) / sampleRate
                                chord4 += (twoPi * 261.63 * vibrato) / sampleRate
                                if (chord1 > twoPi) chord1 -= twoPi
                                if (chord2 > twoPi) chord2 -= twoPi
                                if (chord3 > twoPi) chord3 -= twoPi
                                if (chord4 > twoPi) chord4 -= twoPi
                                val chord = (
                                    sin(chord1).toFloat() * 0.28f +
                                    sin(chord2).toFloat() * 0.24f +
                                    sin(chord3).toFloat() * 0.22f +
                                    sin(chord4).toFloat() * 0.20f
                                ) * breathe * 0.38f
                                if (clinkEnv < 0.0008f && Random.nextFloat() > 0.99996f) {
                                    clinkEnv = 0.35f + Random.nextFloat() * 0.40f
                                    clinkFreq = 2150.0 + Random.nextDouble() * 700.0
                                    clinkPhase = 0.0
                                }
                                var clink = 0f
                                if (clinkEnv > 0.0008f) {
                                    clinkPhase += (twoPi * clinkFreq) / sampleRate
                                    clink = (sin(clinkPhase).toFloat() * 0.65f + sin(clinkPhase * 1.618).toFloat() * 0.35f) * clinkEnv * 0.35f
                                    clinkEnv *= 0.996f
                                }
                                filterState = 0.991f * filterState + 0.009f * white
                                (chord + clink + filterState * 0.25f) * gain
                            }
                            "vinyl" -> {
                                lfoPhase += (twoPi * 0.55) / sampleRate
                                if (lfoPhase > twoPi) lfoPhase -= twoPi
                                chord1 += (twoPi * 60.0) / sampleRate
                                if (chord1 > twoPi) chord1 -= twoPi
                                val platterWarmth = sin(chord1).toFloat() * (0.04f + 0.03f * sin(lfoPhase).toFloat())
                                if (vinylPopEnv < 0.002f && Random.nextFloat() > 0.9991f) {
                                    vinylPopEnv = 0.55f + Random.nextFloat() * 0.45f
                                    vinylPopFreq = 1400.0 + Random.nextDouble() * 1800.0
                                    vinylPopPhase = 0.0
                                }
                                var popSample = 0f
                                if (vinylPopEnv > 0.002f) {
                                    vinylPopPhase += (twoPi * vinylPopFreq) / sampleRate
                                    popSample = sin(vinylPopPhase).toFloat() * vinylPopEnv * 0.75f
                                    vinylPopEnv *= 0.972f
                                }
                                if (vinylCrackleEnv < 0.01f && Random.nextFloat() > 0.994f) {
                                    vinylCrackleEnv = 0.20f + Random.nextFloat() * 0.45f
                                }
                                var crackleSample = 0f
                                if (vinylCrackleEnv > 0.01f) {
                                    crackleSample = white * vinylCrackleEnv * 0.55f
                                    vinylCrackleEnv *= 0.84f
                                }
                                (platterWarmth + popSample + crackleSample) * gain * 1.25f
                            }
                            else -> 0f
                        }
                        buffer[i] = (sample.coerceIn(-0.95f, 0.95f) * Short.MAX_VALUE).toInt().toShort()
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
