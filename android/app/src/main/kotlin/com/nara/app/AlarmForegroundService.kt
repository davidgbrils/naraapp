package com.nara.app

import android.app.NotificationChannel
import android.app.AlarmManager
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import android.media.AudioAttributes
import android.media.Ringtone
import android.media.RingtoneManager
import androidx.core.app.NotificationCompat

class AlarmForegroundService : Service() {
  companion object {
    private const val TAG = "AlarmForegroundService"
    const val ACTION_START = "com.nara.app.action.START_ALARM_SERVICE"
    const val ACTION_STOP = "com.nara.app.action.STOP_ALARM_SERVICE"
    private const val ACTION_SNOOZE = "com.nara.app.action.SNOOZE_ALARM"
    private const val ACTION_COMPLETE = "com.nara.app.action.COMPLETE_ALARM"
    private const val CHANNEL_ID = "native_alarm_foreground_channel_v1"
    private const val NOTIF_ID = 49001
  }

  private val handler = Handler(Looper.getMainLooper())
  private val stopRunnable = Runnable { stopSelfSafely() }
  private var ringtone: Ringtone? = null

  override fun onBind(intent: Intent?): IBinder? = null

  override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
    val action = intent?.action
    Log.i(TAG, "onStartCommand action=$action startId=$startId")
    if (action == ACTION_STOP) {
      Log.i(TAG, "stop requested")
      stopSelfSafely()
      return START_NOT_STICKY
    }
    if (action == ACTION_SNOOZE || action == ACTION_COMPLETE) {
      val reminderId = intent?.getIntExtra("reminder_id", -1) ?: -1
      if (reminderId < 0) {
        stopSelfSafely()
        return START_NOT_STICKY
      }
      val mode = intent?.getStringExtra("mode") ?: "Loud Alarm"
      val title = intent?.getStringExtra("title") ?: "Reminder"
      val body = intent?.getStringExtra("body") ?: "Ada pengingat baru untukmu."
      if (action == ACTION_SNOOZE) {
        scheduleNativeSnooze(reminderId, mode, title, body, 5 * 60 * 1000L)
        notifyFlutterAction(reminderId, "snooze")
      } else {
        notifyFlutterAction(reminderId, "complete")
      }
      clearNotification(reminderId)
      stopSelfSafely()
      return START_NOT_STICKY
    }

    if (action != ACTION_START) {
      return START_NOT_STICKY
    }

    val reminderId = intent.getIntExtra("reminder_id", -1)
    if (reminderId < 0) {
      Log.w(TAG, "invalid reminderId, stopping")
      stopSelfSafely()
      return START_NOT_STICKY
    }
    val mode = intent.getStringExtra("mode") ?: "Loud Alarm"
    val title = intent.getStringExtra("title") ?: "Reminder"
    val body = intent.getStringExtra("body") ?: "Ada pengingat baru untukmu."

    ensureChannel()
    val completeIntent = Intent(this, AlarmForegroundService::class.java).apply {
      this.action = ACTION_COMPLETE
      putExtra("reminder_id", reminderId)
      putExtra("mode", mode)
      putExtra("title", title)
      putExtra("body", body)
    }
    val snoozeIntent = Intent(this, AlarmForegroundService::class.java).apply {
      this.action = ACTION_SNOOZE
      putExtra("reminder_id", reminderId)
      putExtra("mode", mode)
      putExtra("title", title)
      putExtra("body", body)
    }
    val completePendingIntent = PendingIntent.getService(
      this,
      reminderId + 2100000,
      completeIntent,
      PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )
    val snoozePendingIntent = PendingIntent.getService(
      this,
      reminderId + 2200000,
      snoozeIntent,
      PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    val notification = NotificationCompat.Builder(this, CHANNEL_ID)
      .setSmallIcon(R.mipmap.ic_launcher)
      .setContentTitle(title)
      .setContentText(body)
      .setCategory(NotificationCompat.CATEGORY_ALARM)
      .setPriority(NotificationCompat.PRIORITY_MAX)
      .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
      .setOngoing(true)
      .setAutoCancel(false)
      .setVibrate(longArrayOf(0, 800, 400, 800))
      .setOnlyAlertOnce(false)
      .addAction(0, "Selesai", completePendingIntent)
      .addAction(0, "Tunda 5 Menit", snoozePendingIntent)
      .build()

    try {
      // Use the safest foreground start path across OEMs/API levels.
      // Some devices crash when a specific foreground service type is declared
      // without matching runtime/manifest expectations.
      startForeground(NOTIF_ID, notification)
      Log.i(TAG, "startForeground success id=$reminderId mode=$mode")
      startAlarmSound()
    } catch (e: Exception) {
      Log.e(TAG, "startForeground failed id=$reminderId", e)
      stopSelfSafely()
      return START_NOT_STICKY
    }

    handler.postDelayed(
      {
        try {
          scheduleNativeSnooze(reminderId, mode, title, body, 5 * 60 * 1000L)
          notifyFlutterAction(reminderId, "snooze")
          clearNotification(reminderId)
          stopSelfSafely()
          Log.i(TAG, "auto snooze executed id=$reminderId")
        } catch (e: Exception) {
          Log.e(TAG, "auto snooze failed id=$reminderId", e)
        }
      },
      60_000L,
    )

    handler.removeCallbacks(stopRunnable)
    handler.postDelayed(stopRunnable, 180_000L)
    return START_NOT_STICKY
  }

  override fun onDestroy() {
    handler.removeCallbacks(stopRunnable)
    stopAlarmSound()
    super.onDestroy()
  }

  private fun stopSelfSafely() {
    Log.i(TAG, "stopSelfSafely")
    stopAlarmSound()
    stopForeground(STOP_FOREGROUND_REMOVE)
    stopSelf()
  }

  private fun startAlarmSound() {
    try {
      val soundUri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
      ringtone = RingtoneManager.getRingtone(this, soundUri)
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
        ringtone?.audioAttributes = AudioAttributes.Builder()
          .setUsage(AudioAttributes.USAGE_ALARM)
          .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
          .build()
      }
      ringtone?.play()
      Log.i(TAG, "alarm ringtone started")
    } catch (e: Exception) {
      Log.e(TAG, "failed to start ringtone", e)
    }
  }

  private fun stopAlarmSound() {
    try {
      ringtone?.stop()
      ringtone = null
    } catch (_: Exception) {}
  }

  private fun scheduleNativeSnooze(
    reminderId: Int,
    mode: String,
    title: String,
    body: String,
    delayMillis: Long
  ) {
    val triggerAt = System.currentTimeMillis() + delayMillis
    val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
    val intent = Intent(this, ReminderPopupAlarmReceiver::class.java).apply {
      action = "com.nara.app.POPUP_REMINDER_ALARM"
      putExtra("reminder_id", reminderId)
      putExtra("mode", mode)
      putExtra("title", title)
      putExtra("body", body)
    }
    val pendingIntent = PendingIntent.getBroadcast(
      this,
      reminderId,
      intent,
      PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
    )
    val clockInfo = AlarmManager.AlarmClockInfo(triggerAt, pendingIntent)
    alarmManager.setAlarmClock(clockInfo, pendingIntent)
  }

  private fun notifyFlutterAction(reminderId: Int, action: String) {
    val launchIntent = Intent(this, MainActivity::class.java).apply {
      flags = Intent.FLAG_ACTIVITY_NEW_TASK or
          Intent.FLAG_ACTIVITY_SINGLE_TOP or
          Intent.FLAG_ACTIVITY_CLEAR_TOP
      putExtra("from_popup_alarm", true)
      putExtra("popup_action", action)
      putExtra("reminder_id", reminderId)
    }
    startActivity(launchIntent)
  }

  private fun clearNotification(reminderId: Int) {
    val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    manager.cancel(reminderId)
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
