package com.nara.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat
import android.app.PendingIntent

class ReminderPopupAlarmReceiver : BroadcastReceiver() {
  companion object {
    private const val CHANNEL_ID = "native_alarm_popup_channel_v2"
  }

  override fun onReceive(context: Context, intent: Intent?) {
    val reminderId = intent?.getIntExtra("reminder_id", -1) ?: -1
    if (reminderId < 0) return

    val mode = intent?.getStringExtra("mode") ?: "Loud Alarm"
    val title = intent?.getStringExtra("title") ?: "Reminder"
    val body = intent?.getStringExtra("body") ?: "Ada pengingat baru untukmu."

    try {
      val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
      val wakeLock = powerManager.newWakeLock(
        PowerManager.PARTIAL_WAKE_LOCK,
        "nara:popup_alarm_wakelock",
      )
      wakeLock.acquire(8_000L)
    } catch (_: Exception) {
      // Ignore wakelock issues to avoid receiver crash.
    }

    val alertIntent = Intent(context, AlarmAlertActivity::class.java).apply {
      flags = Intent.FLAG_ACTIVITY_NEW_TASK or
          Intent.FLAG_ACTIVITY_SINGLE_TOP or
          Intent.FLAG_ACTIVITY_CLEAR_TOP
      putExtra("from_popup_alarm", true)
      putExtra("reminder_id", reminderId)
      putExtra("mode", mode)
      putExtra("title", title)
      putExtra("body", body)
    }

    val fullScreenPendingIntent = PendingIntent.getActivity(
      context,
      reminderId,
      alertIntent,
      PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    try {
      ensureChannel(context)
      val notificationManager =
        context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
      val notification = NotificationCompat.Builder(context, CHANNEL_ID)
        .setSmallIcon(R.mipmap.ic_launcher)
        .setContentTitle(title)
        .setContentText(body)
        .setCategory(
          if (mode == "Fake Call") NotificationCompat.CATEGORY_CALL
          else NotificationCompat.CATEGORY_ALARM,
        )
        .setPriority(NotificationCompat.PRIORITY_MAX)
        .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
        .setAutoCancel(false)
        .setOngoing(true)
        .setFullScreenIntent(fullScreenPendingIntent, true)
        .setContentIntent(fullScreenPendingIntent)
        .setVibrate(longArrayOf(0, 700, 300, 700))
        .build()
      notificationManager.notify(reminderId, notification)

      // Try direct launch for immediate alarm UX; fullScreenIntent remains fallback.
      context.startActivity(alertIntent)

      Log.i(
        "ReminderPopupAlarm",
        "Alarm popup shown for reminderId=$reminderId mode=$mode",
      )
    } catch (e: Exception) {
      Log.e(
        "ReminderPopupAlarm",
        "Failed showing alarm popup for reminderId=$reminderId",
        e,
      )
    }
  }

  private fun ensureChannel(context: Context) {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
    val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    if (manager.getNotificationChannel(CHANNEL_ID) != null) return
    manager.createNotificationChannel(
      NotificationChannel(
        CHANNEL_ID,
        "Nara Alarm Popup",
        NotificationManager.IMPORTANCE_HIGH,
      ).apply {
        description = "Alarm popup notification channel"
        lockscreenVisibility = NotificationCompat.VISIBILITY_PUBLIC
        enableVibration(true)
      },
    )
  }
}
