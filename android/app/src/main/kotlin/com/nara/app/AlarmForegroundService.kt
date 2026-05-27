package com.nara.app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat

class AlarmForegroundService : Service() {
  companion object {
    const val ACTION_START = "com.nara.app.action.START_ALARM_SERVICE"
    const val ACTION_STOP = "com.nara.app.action.STOP_ALARM_SERVICE"
    private const val CHANNEL_ID = "native_alarm_foreground_channel_v1"
    private const val NOTIF_ID = 49001
  }

  private val handler = Handler(Looper.getMainLooper())
  private val stopRunnable = Runnable { stopSelfSafely() }

  override fun onBind(intent: Intent?): IBinder? = null

  override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
    val action = intent?.action
    if (action == ACTION_STOP) {
      stopSelfSafely()
      return START_NOT_STICKY
    }

    if (action != ACTION_START) {
      return START_NOT_STICKY
    }

    val reminderId = intent.getIntExtra("reminder_id", -1)
    if (reminderId < 0) {
      stopSelfSafely()
      return START_NOT_STICKY
    }
    val mode = intent.getStringExtra("mode") ?: "Loud Alarm"
    val title = intent.getStringExtra("title") ?: "Reminder"
    val body = intent.getStringExtra("body") ?: "Ada pengingat baru untukmu."

    ensureChannel()
    val fullScreenIntent = Intent(this, AlarmAlertActivity::class.java).apply {
      this.flags = Intent.FLAG_ACTIVITY_NEW_TASK or
          Intent.FLAG_ACTIVITY_SINGLE_TOP or
          Intent.FLAG_ACTIVITY_CLEAR_TOP
      putExtra("from_popup_alarm", true)
      putExtra("reminder_id", reminderId)
      putExtra("mode", mode)
      putExtra("title", title)
      putExtra("body", body)
    }
    val fullScreenPendingIntent = PendingIntent.getActivity(
      this,
      reminderId,
      fullScreenIntent,
      PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    val notification = NotificationCompat.Builder(this, CHANNEL_ID)
      .setSmallIcon(R.mipmap.ic_launcher)
      .setContentTitle(title)
      .setContentText(body)
      .setCategory(
        if (mode == "Fake Call") NotificationCompat.CATEGORY_CALL
        else NotificationCompat.CATEGORY_ALARM
      )
      .setPriority(NotificationCompat.PRIORITY_MAX)
      .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
      .setOngoing(true)
      .setAutoCancel(false)
      .setVibrate(longArrayOf(0, 800, 400, 800))
      .setFullScreenIntent(fullScreenPendingIntent, true)
      .setContentIntent(fullScreenPendingIntent)
      .build()

    try {
      // Use the safest foreground start path across OEMs/API levels.
      // Some devices crash when a specific foreground service type is declared
      // without matching runtime/manifest expectations.
      startForeground(NOTIF_ID, notification)
    } catch (_: Exception) {
      stopSelfSafely()
      return START_NOT_STICKY
    }

    try {
      startActivity(fullScreenIntent)
    } catch (_: Exception) {
      // Notification fullScreenIntent remains as fallback.
    }

    handler.removeCallbacks(stopRunnable)
    handler.postDelayed(stopRunnable, 180_000L)
    return START_NOT_STICKY
  }

  override fun onDestroy() {
    handler.removeCallbacks(stopRunnable)
    super.onDestroy()
  }

  private fun stopSelfSafely() {
    stopForeground(STOP_FOREGROUND_REMOVE)
    stopSelf()
  }

  private fun ensureChannel() {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
    val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    val channel = manager.getNotificationChannel(CHANNEL_ID)
    if (channel != null) return
    manager.createNotificationChannel(
      NotificationChannel(
        CHANNEL_ID,
        "Nara Alarm Foreground",
        NotificationManager.IMPORTANCE_HIGH,
      ).apply {
        description = "Foreground alarm service for reliable popup alerts"
        lockscreenVisibility = NotificationCompat.VISIBILITY_PUBLIC
        enableVibration(true)
      },
    )
  }
}
