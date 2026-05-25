package com.nara.app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.PowerManager
import android.util.Log

class ReminderPopupAlarmReceiver : BroadcastReceiver() {
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

    val serviceIntent = Intent(context, AlarmForegroundService::class.java).apply {
      action = AlarmForegroundService.ACTION_START
      putExtra("reminder_id", reminderId)
      putExtra("mode", mode)
      putExtra("title", title)
      putExtra("body", body)
    }

    try {
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        context.startForegroundService(serviceIntent)
      } else {
        context.startService(serviceIntent)
      }
      Log.i(
        "ReminderPopupAlarm",
        "AlarmForegroundService started for reminderId=$reminderId mode=$mode",
      )
    } catch (e: Exception) {
      Log.e(
        "ReminderPopupAlarm",
        "Failed starting AlarmForegroundService for reminderId=$reminderId",
        e,
      )
    }
  }
}

