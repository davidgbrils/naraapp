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
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.util.Log
import android.widget.RemoteViews
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
    private const val ACTION_DISMISS_TRIGGER = "com.nara.app.action.DISMISS_WAKE_WORD_TRIGGER"
    private const val CHANNEL_ID = "wake_word_foreground_channel_v1"
    private const val TRIGGER_CHANNEL_ID = "wake_word_trigger_channel_v1"
    private const val NOTIF_ID = 59001
    private const val TRIGGER_NOTIF_ID = 59004
    private const val MODEL_ASSET_DIR = "vosk-model-small-en-us-0.15"
    private const val MODEL_STORAGE_DIR = "wake-word-model"
    private const val DEFAULT_WAKE_PHRASE = "hey nara"
    private const val COMMAND_LISTEN_TIMEOUT_MS = 10_000L
    var isRunning: Boolean = false
      private set
  }

  private var speechService: SpeechService? = null
  private var model: Model? = null
  private var isDetecting = false
  private var isCommandMode = false
  private var lastLaunchAtMillis = 0L
  private var lastCommandText = ""
  private var wakePhrase = DEFAULT_WAKE_PHRASE
  private val commandTimeoutHandler = Handler(Looper.getMainLooper())
  private val commandTimeoutRunnable = Runnable { finishWakeCommand() }

  override fun onBind(intent: Intent?): IBinder? = null

  override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
    when (intent?.action) {
      ACTION_DISMISS_TRIGGER -> {
        stopWakeWord()
        dismissWakeWordTriggerNotification()
        stopSelf()
        return START_NOT_STICKY
      }
      ACTION_STOP -> {
        stopWakeWord()
        dismissWakeWordTriggerNotification()
        stopSelf()
        return START_NOT_STICKY
      }
      ACTION_START, null -> {
        wakePhrase = normalizeWakeText(intent?.getStringExtra("wake_phrase") ?: DEFAULT_WAKE_PHRASE)
          .ifBlank { DEFAULT_WAKE_PHRASE }
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
      val grammar = buildWakeGrammar()
      val recognizer = Recognizer(loadedModel, 16000.0f, grammar)
      speechService = SpeechService(recognizer, 16000.0f)
      speechService?.startListening(this)
      updateNotification("NARA Wake Word aktif", "Ucapkan \"$wakePhrase\" untuk mulai.")
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
    isCommandMode = false
    lastCommandText = ""
    commandTimeoutHandler.removeCallbacks(commandTimeoutRunnable)
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
      startForeground(NOTIF_ID, buildNotification("NARA Wake Word aktif", "Ucapkan \"$wakePhrase\" untuk mulai."))
      true
    } catch (exception: Exception) {
      Log.e(TAG, "Failed to promote wake word service to foreground", exception)
      false
    }
  }

  override fun onPartialResult(hypothesis: String?) {
    handleHypothesis(hypothesis, allowWakeTrigger = false, finishCommandOnText = false)
  }

  override fun onResult(hypothesis: String?) {
    handleHypothesis(hypothesis, allowWakeTrigger = true, finishCommandOnText = false)
  }

  override fun onFinalResult(hypothesis: String?) {
    val wasCommandMode = isCommandMode
    handleHypothesis(hypothesis, allowWakeTrigger = true, finishCommandOnText = true)
    if (wasCommandMode && isCommandMode && lastCommandText.isNotBlank()) {
      finishWakeCommand()
    } else if (wasCommandMode && isCommandMode && speechService != null) {
      speechService?.startListening(this)
    }
  }

  override fun onError(exception: Exception?) {
    Log.e(TAG, "Wake word recognition error", exception)
    isDetecting = false
    updateNotification("Wake Word berhenti", "Coba aktifkan ulang dari Pengaturan.")
  }

  override fun onTimeout() {
    if (isCommandMode) {
      finishWakeCommand()
    } else if (isDetecting && speechService != null) {
      speechService?.startListening(this)
    }
  }

  private fun handleHypothesis(
    hypothesis: String?,
    allowWakeTrigger: Boolean,
    finishCommandOnText: Boolean,
  ) {
    val text = normalizeWakeText(extractText(hypothesis))
    if (text.isBlank()) return
    if (isCommandMode) {
      handleWakeCommandText(text, finishCommandOnText)
      return
    }
    if (allowWakeTrigger && isWakeWord(text)) {
      Log.i(TAG, "Wake word detected: $text")
      startWakeCommandMode(text)
    }
  }

  private fun handleWakeCommandText(text: String, finishCommandOnText: Boolean) {
    val commandText = stripWakePhrase(text)
    if (commandText.isBlank()) return
    lastCommandText = commandText
    showWakeWordDetectedNotification(
      capturedText = commandText,
      subtitle = "NARA mendengarkan. Lanjut bicara, lalu buka untuk konfirmasi.",
      capturedPrefix = "Kamu bilang:",
      fullScreen = false,
      autoCancel = false,
    )
    if (finishCommandOnText) {
      finishWakeCommand()
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
    val words = text.split(" ").filter { it.isNotBlank() }
    val phraseWords = wakePhrase.split(" ").filter { it.isNotBlank() }
    if (phraseWords.size < 2 || words.size < phraseWords.size) return false
    return words.windowed(phraseWords.size).any { window ->
      window.zip(phraseWords).all { (heard, expected) -> wordsMatch(heard, expected) }
    }
  }

  private fun wordsMatch(heard: String, expected: String): Boolean {
    if (heard == expected) return true
    if (expected == "hey") return heard == "hay" || heard == "hai" || heard == "hei"
    if (expected == "hay") return heard == "hey" || heard == "hai" || heard == "hei"
    if (expected == "hai") return heard == "hey" || heard == "hay" || heard == "hei"
    if (expected == "nara") return heard == "naara" || heard == "narra" || heard == "nora"
    return false
  }

  private fun buildWakeGrammar(): String {
    val phrases = linkedSetOf(wakePhrase)
    if (wakePhrase == DEFAULT_WAKE_PHRASE) {
      phrases.add("hay nara")
      phrases.add("hai nara")
      phrases.add("hei nara")
    }
    phrases.add("[unk]")
    return phrases.joinToString(prefix = "[", postfix = "]") { "\"$it\"" }
  }

  private fun stripWakePhrase(text: String): String {
    val words = text.split(" ").filter { it.isNotBlank() }
    val phraseWords = wakePhrase.split(" ").filter { it.isNotBlank() }
    if (phraseWords.size < 2) return text
    val wakeIndex = words.windowed(phraseWords.size).indexOfFirst { window ->
      window.zip(phraseWords).all { (heard, expected) -> wordsMatch(heard, expected) }
    }
    if (wakeIndex < 0) return text
    return words.drop(wakeIndex + phraseWords.size).joinToString(" ").trim()
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

  private fun startWakeCommandMode(wakeText: String) {
    val now = System.currentTimeMillis()
    if (now - lastLaunchAtMillis < 2500) return
    lastLaunchAtMillis = now
    isCommandMode = true
    lastCommandText = stripWakePhrase(wakeText)
    val launchPendingIntent = buildWakeWordPendingIntent()
    showWakeWordDetectedNotification(
      launchPendingIntent = launchPendingIntent,
      capturedText = lastCommandText.ifBlank { wakePhrase },
      subtitle = "Wake word aktif. Silakan langsung bicara kebutuhan kamu.",
      capturedPrefix = if (lastCommandText.isBlank()) "Terdengar:" else "Kamu bilang:",
      fullScreen = false,
      autoCancel = false,
    )
    wakeScreenBriefly()
    startCommandListening()
    commandTimeoutHandler.removeCallbacks(commandTimeoutRunnable)
    commandTimeoutHandler.postDelayed(commandTimeoutRunnable, COMMAND_LISTEN_TIMEOUT_MS)
  }

  private fun startCommandListening() {
    val loadedModel = model ?: return
    try {
      speechService?.stop()
      speechService?.shutdown()
    } catch (_: Exception) {}
    try {
      val recognizer = Recognizer(loadedModel, 16000.0f)
      speechService = SpeechService(recognizer, 16000.0f)
      speechService?.startListening(this)
      updateNotification("NARA mendengarkan perintah", "Lanjut bicara setelah \"$wakePhrase\".")
    } catch (exception: Exception) {
      Log.e(TAG, "Failed starting wake command listening", exception)
      finishWakeCommand()
    }
  }

  private fun finishWakeCommand() {
    if (!isCommandMode) return
    commandTimeoutHandler.removeCallbacks(commandTimeoutRunnable)
    val capturedText = lastCommandText.ifBlank { "Belum ada kalimat yang tertangkap." }
    isCommandMode = false
    try {
      speechService?.stop()
      speechService?.shutdown()
    } catch (_: Exception) {}
    speechService = null
    try {
      model?.close()
    } catch (_: Exception) {}
    model = null
    isDetecting = false
    isRunning = false
    try {
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
        stopForeground(STOP_FOREGROUND_REMOVE)
      } else {
        @Suppress("DEPRECATION")
        stopForeground(true)
      }
    } catch (_: Exception) {}
    showWakeWordDetectedNotification(
      capturedText = capturedText,
      subtitle = "Tap Buka NARA untuk cek dan konfirmasi perintah.",
      capturedPrefix = if (lastCommandText.isBlank()) "Status:" else "Kamu bilang:",
      fullScreen = false,
      autoCancel = true,
    )
    stopSelf()
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

  private fun buildWakeWordDismissPendingIntent(): PendingIntent {
    return PendingIntent.getService(
      this,
      59006,
      Intent(this, WakeWordForegroundService::class.java).apply {
        action = ACTION_DISMISS_TRIGGER
      },
      PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )
  }

  private fun showWakeWordDetectedNotification(
    launchPendingIntent: PendingIntent = buildWakeWordPendingIntent(),
    capturedText: String = wakePhrase,
    subtitle: String = "Buka NARA untuk lanjut bicara.",
    capturedPrefix: String = "Terdengar:",
    fullScreen: Boolean = false,
    autoCancel: Boolean = true,
  ) {
    ensureTriggerChannel()
    val dismissPendingIntent = buildWakeWordDismissPendingIntent()
    val popupView = RemoteViews(packageName, R.layout.notification_wake_word_popup).apply {
      setTextViewText(R.id.wake_word_status, "VOICE AKTIF")
      setTextViewText(R.id.wake_word_title, "NARA mendengar kamu")
      setTextViewText(R.id.wake_word_subtitle, subtitle)
      setTextViewText(R.id.wake_word_captured_text, "$capturedPrefix $capturedText")
      setOnClickPendingIntent(R.id.wake_word_open, launchPendingIntent)
      setOnClickPendingIntent(R.id.wake_word_cancel, dismissPendingIntent)
    }
    val builder = NotificationCompat.Builder(this, TRIGGER_CHANNEL_ID)
      .setSmallIcon(R.mipmap.ic_launcher)
      .setContentTitle("NARA mendengar kamu")
      .setContentText("Tap untuk lanjut bicara dengan NARA.")
      .setCategory(NotificationCompat.CATEGORY_ALARM)
      .setPriority(NotificationCompat.PRIORITY_MAX)
      .setDefaults(NotificationCompat.DEFAULT_ALL)
      .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
      .setAutoCancel(autoCancel)
      .setContentIntent(launchPendingIntent)
      .setCustomContentView(popupView)
      .setCustomBigContentView(popupView)
      .setStyle(NotificationCompat.DecoratedCustomViewStyle())
      .addAction(0, "Batal", dismissPendingIntent)
      .addAction(0, "Buka NARA", launchPendingIntent)
    if (fullScreen) {
      builder.setFullScreenIntent(launchPendingIntent, true)
    }
    val notification = builder.build()
    val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    manager.notify(TRIGGER_NOTIF_ID, notification)
  }

  private fun dismissWakeWordTriggerNotification() {
    try {
      val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
      manager.cancel(TRIGGER_NOTIF_ID)
    } catch (exception: Exception) {
      Log.e(TAG, "Failed dismissing wake word trigger notification", exception)
    }
  }

  private fun wakeScreenBriefly() {
    try {
      val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
      @Suppress("DEPRECATION")
      val wakeLock = powerManager.newWakeLock(
        PowerManager.SCREEN_BRIGHT_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP,
        "nara:wake_word_launch",
      )
      wakeLock.acquire(4_000L)
    } catch (exception: Exception) {
      Log.e(TAG, "Failed to briefly wake screen for wake word", exception)
    }
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
