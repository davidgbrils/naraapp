package com.nara.app

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import org.json.JSONObject
import org.vosk.Model
import org.vosk.Recognizer
import org.vosk.android.RecognitionListener
import org.vosk.android.SpeechService
import org.vosk.android.StorageService

class WakeWordForegroundService : Service(), RecognitionListener {
  companion object {
    private const val TAG = "WakeWordService"
    const val ACTION_START = "com.nara.app.action.START_WAKE_WORD"
    const val ACTION_STOP = "com.nara.app.action.STOP_WAKE_WORD"
    private const val CHANNEL_ID = "wake_word_foreground_channel_v1"
    private const val TRIGGER_CHANNEL_ID = "wake_word_trigger_channel_v1"
    private const val NOTIF_ID = 59001
    private const val TRIGGER_NOTIF_ID = 59004
    private const val MODEL_ASSET_DIR = "vosk-model-small-en-us-0.15"
    private const val MODEL_STORAGE_DIR = "wake-word-model"
    var isRunning: Boolean = false
      private set
  }

  private var speechService: SpeechService? = null
  private var model: Model? = null
  private var isDetecting = false
  private var lastLaunchAtMillis = 0L

  override fun onBind(intent: Intent?): IBinder? = null

  override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
    when (intent?.action) {
      ACTION_STOP -> {
        stopWakeWord()
        stopSelf()
        return START_NOT_STICKY
      }
      ACTION_START, null -> {
        isRunning = true
        if (!promoteToForeground()) {
          isRunning = false
          stopSelf()
          return START_NOT_STICKY
        }
        startWakeWord()
        return START_STICKY
      }
      else -> return START_NOT_STICKY
    }
  }

  override fun onDestroy() {
    stopWakeWord()
    super.onDestroy()
  }

  private fun startWakeWord() {
    if (isDetecting) return
    if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
      updateNotification("Wake Word butuh izin mikrofon", "Aktifkan izin mikrofon untuk memakai Hay NARA.")
      return
    }
    isDetecting = true
    try {
      StorageService.unpack(
        this,
        MODEL_ASSET_DIR,
        MODEL_STORAGE_DIR,
        { loadedModel ->
          model = loadedModel
          startVoskListening(loadedModel)
        },
        { exception ->
          Log.e(TAG, "Vosk model unavailable", exception)
          isDetecting = false
          updateNotification(
            "Wake Word belum siap",
            "Model offline Vosk belum tersedia di assets/$MODEL_ASSET_DIR.",
          )
        },
      )
    } catch (e: Exception) {
      Log.e(TAG, "Failed starting wake word", e)
      isDetecting = false
      updateNotification("Wake Word gagal aktif", "Coba aktifkan ulang dari Pengaturan.")
    }
  }

  private fun startVoskListening(loadedModel: Model) {
    try {
      val grammar = "[\"hey nara\", \"hay nara\", \"hai nara\", \"hei nara\", \"nara\", \"nora\", \"nara app\", \"[unk]\"]"
      val recognizer = Recognizer(loadedModel, 16000.0f, grammar)
      speechService = SpeechService(recognizer, 16000.0f)
      speechService?.startListening(this)
      updateNotification("NARA Wake Word aktif", "Ucapkan \"Hay NARA\" untuk mulai.")
      Log.i(TAG, "Vosk wake word listening started")
    } catch (e: Exception) {
      Log.e(TAG, "Failed starting Vosk listening", e)
      isDetecting = false
      updateNotification("Wake Word gagal aktif", "Engine offline tidak bisa dimulai.")
    }
  }

  private fun stopWakeWord() {
    isRunning = false
    isDetecting = false
    try {
      speechService?.stop()
      speechService?.shutdown()
    } catch (_: Exception) {}
    speechService = null
    try {
      model?.close()
    } catch (_: Exception) {}
    model = null
    try {
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
        stopForeground(STOP_FOREGROUND_REMOVE)
      } else {
        @Suppress("DEPRECATION")
        stopForeground(true)
      }
    } catch (_: Exception) {}
  }

  private fun promoteToForeground(): Boolean {
    return try {
      startForeground(NOTIF_ID, buildNotification("NARA Wake Word aktif", "Ucapkan \"Hay NARA\" untuk mulai."))
      true
    } catch (exception: Exception) {
      Log.e(TAG, "Failed to promote wake word service to foreground", exception)
      false
    }
  }

  override fun onPartialResult(hypothesis: String?) {
    handleHypothesis(hypothesis)
  }

  override fun onResult(hypothesis: String?) {
    handleHypothesis(hypothesis)
  }

  override fun onFinalResult(hypothesis: String?) {
    handleHypothesis(hypothesis)
  }

  override fun onError(exception: Exception?) {
    Log.e(TAG, "Wake word recognition error", exception)
    isDetecting = false
    updateNotification("Wake Word berhenti", "Coba aktifkan ulang dari Pengaturan.")
  }

  override fun onTimeout() {
    if (isDetecting && speechService != null) {
      speechService?.startListening(this)
    }
  }

  private fun handleHypothesis(hypothesis: String?) {
    val text = normalizeWakeText(extractText(hypothesis))
    if (text.isBlank()) return
    if (isWakeWord(text)) {
      Log.i(TAG, "Wake word detected: $text")
      launchWakeWord()
    }
  }

  private fun normalizeWakeText(text: String): String {
    return text
      .lowercase()
      .replace(Regex("[^a-z\\s]"), " ")
      .replace(Regex("\\s+"), " ")
      .trim()
  }

  private fun isWakeWord(text: String): Boolean {
    if (text.isBlank()) return false
    val compact = text.replace(" ", "")
    return text.contains("hey nara") ||
        text.contains("hay nara") ||
        text.contains("hai nara") ||
        text.contains("hei nara") ||
        text.contains("nara") ||
        text.contains("nora") ||
        compact.contains("nara") ||
        compact.contains("nora") ||
        compact.contains("narra") ||
        compact.contains("naara") ||
        text.contains("nara app")
  }

  private fun extractText(raw: String?): String {
    if (raw.isNullOrBlank()) return ""
    return try {
      val json = JSONObject(raw)
      json.optString("partial").ifBlank { json.optString("text") }
    } catch (_: Exception) {
      raw
    }
  }

  private fun launchWakeWord() {
    val now = System.currentTimeMillis()
    if (now - lastLaunchAtMillis < 2500) return
    lastLaunchAtMillis = now
    stopWakeWord()
    showWakeWordDetectedNotification()
    try {
      startActivity(buildWakeWordLaunchIntent())
    } catch (exception: Exception) {
      Log.e(TAG, "Background launch blocked; wake notification posted", exception)
    }
  }

  private fun buildWakeWordLaunchIntent(): Intent {
    return Intent(this, MainActivity::class.java).apply {
      flags = Intent.FLAG_ACTIVITY_NEW_TASK or
          Intent.FLAG_ACTIVITY_SINGLE_TOP or
          Intent.FLAG_ACTIVITY_CLEAR_TOP
      putExtra("from_wake_word", true)
    }
  }

  private fun buildWakeWordPendingIntent(): PendingIntent {
    return PendingIntent.getActivity(
      this,
      59005,
      buildWakeWordLaunchIntent(),
      PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )
  }

  private fun showWakeWordDetectedNotification() {
    ensureTriggerChannel()
    val launchPendingIntent = buildWakeWordPendingIntent()
    val notification = NotificationCompat.Builder(this, TRIGGER_CHANNEL_ID)
      .setSmallIcon(R.mipmap.ic_launcher)
      .setContentTitle("NARA mendengar kamu")
      .setContentText("Tap untuk lanjut bicara dengan NARA.")
      .setCategory(NotificationCompat.CATEGORY_ALARM)
      .setPriority(NotificationCompat.PRIORITY_MAX)
      .setAutoCancel(true)
      .setContentIntent(launchPendingIntent)
      .setFullScreenIntent(launchPendingIntent, true)
      .build()
    val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    manager.notify(TRIGGER_NOTIF_ID, notification)
  }

  private fun buildNotification(title: String, body: String): android.app.Notification {
    ensureChannel()
    val openIntent = PendingIntent.getActivity(
      this,
      59002,
      Intent(this, MainActivity::class.java).apply {
        flags = Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP
      },
      PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )
    val stopIntent = PendingIntent.getService(
      this,
      59003,
      Intent(this, WakeWordForegroundService::class.java).apply { action = ACTION_STOP },
      PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )
    return NotificationCompat.Builder(this, CHANNEL_ID)
      .setSmallIcon(R.mipmap.ic_launcher)
      .setContentTitle(title)
      .setContentText(body)
      .setOngoing(true)
      .setCategory(NotificationCompat.CATEGORY_SERVICE)
      .setPriority(NotificationCompat.PRIORITY_LOW)
      .setContentIntent(openIntent)
      .addAction(0, "Stop", stopIntent)
      .build()
  }

  private fun updateNotification(title: String, body: String) {
    val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    manager.notify(NOTIF_ID, buildNotification(title, body))
  }

  private fun ensureChannel() {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
    val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    if (manager.getNotificationChannel(CHANNEL_ID) != null) return
    manager.createNotificationChannel(
      NotificationChannel(
        CHANNEL_ID,
        "NARA Wake Word",
        NotificationManager.IMPORTANCE_LOW,
      ).apply {
        description = "Foreground microphone service for Hay NARA wake word"
      },
    )
  }

  private fun ensureTriggerChannel() {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
    val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    if (manager.getNotificationChannel(TRIGGER_CHANNEL_ID) != null) return
    manager.createNotificationChannel(
      NotificationChannel(
        TRIGGER_CHANNEL_ID,
        "NARA Wake Word Trigger",
        NotificationManager.IMPORTANCE_HIGH,
      ).apply {
        description = "Opens NARA when the Hay NARA wake word is detected"
        lockscreenVisibility = android.app.Notification.VISIBILITY_PUBLIC
      },
    )
  }
}
