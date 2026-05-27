package com.nara.app

import android.app.AlarmManager
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
  private val popupAlarmChannel = "nara/reminder_popup_alarm"
  private var popupChannel: MethodChannel? = null
  private var pendingPopupReminderId: Int? = null
  private var latestPopupReminderId: Int? = null
  private var pendingPopupAction: Map<String, Any?>? = null

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    popupChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, popupAlarmChannel)
    popupChannel
      ?.setMethodCallHandler { call, result ->
        when (call.method) {
          "schedulePopupAlarm" -> {
            val id = call.argument<Int>("id")
            val triggerAtMillis = call.argument<Long>("triggerAtMillis")
            val mode = call.argument<String>("mode") ?: "Loud Alarm"
            val title = call.argument<String>("title") ?: "Reminder"
            val body = call.argument<String>("body") ?: "Ada pengingat baru untukmu."
            if (id == null || triggerAtMillis == null) {
              result.error("invalid_args", "Missing id/triggerAtMillis", null)
              return@setMethodCallHandler
            }
            schedulePopupAlarm(id, triggerAtMillis, mode, title, body)
            result.success(true)
          }

          "cancelPopupAlarm" -> {
            val id = call.argument<Int>("id")
            if (id == null) {
              result.error("invalid_args", "Missing id", null)
              return@setMethodCallHandler
            }
            cancelPopupAlarm(id)
            result.success(true)
          }

          "getNativeReminderHealth" -> {
            val notificationManager =
              getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager

            val fullScreenIntentGranted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
              notificationManager.canUseFullScreenIntent()
            } else {
              null
            }
            val batteryOptimizationIgnored =
              powerManager.isIgnoringBatteryOptimizations(packageName)

            result.success(
              mapOf(
                "fullScreenIntentGranted" to fullScreenIntentGranted,
                "batteryOptimizationIgnored" to batteryOptimizationIgnored,
              )
            )
          }

          "openReminderSystemSettings" -> {
            val target = call.argument<String>("target") ?: "app"
            openReminderSystemSettings(target)
            result.success(true)
          }

          "consumePendingPopupAlarm" -> {
            val id = latestPopupReminderId
            latestPopupReminderId = null
            result.success(id)
          }

          "consumePendingPopupAction" -> {
            val action = pendingPopupAction
            pendingPopupAction = null
            result.success(action)
          }

          else -> result.notImplemented()
        }
      }
    flushPendingPopupReminder()
    flushPendingPopupAction()
    relayPopupAlarmFromIntent(intent)
  }

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    relayPopupAlarmFromIntent(intent)
  }

  override fun onNewIntent(intent: Intent) {
    super.onNewIntent(intent)
    setIntent(intent)
    relayPopupAlarmFromIntent(intent)
  }

  private fun schedulePopupAlarm(
    id: Int,
    triggerAtMillis: Long,
    mode: String,
    title: String,
    body: String
  ) {
    val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
    val pendingIntent = popupPendingIntent(id, mode, title, body)
    val showIntent = PendingIntent.getActivity(
      this,
      id + 900000,
      Intent(this, MainActivity::class.java).apply {
        flags = Intent.FLAG_ACTIVITY_NEW_TASK or
            Intent.FLAG_ACTIVITY_SINGLE_TOP or
            Intent.FLAG_ACTIVITY_CLEAR_TOP
        putExtra("from_popup_alarm", true)
        putExtra("reminder_id", id)
      },
      PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
    )

    val clockInfo = AlarmManager.AlarmClockInfo(triggerAtMillis, showIntent)
    alarmManager.setAlarmClock(clockInfo, pendingIntent)
  }

  private fun cancelPopupAlarm(id: Int) {
    val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
    alarmManager.cancel(popupBroadcastPendingIntent(id))
    alarmManager.cancel(popupActivityPendingIntent(id))
  }

  private fun popupPendingIntent(
    id: Int,
    mode: String = "Loud Alarm",
    title: String = "Reminder",
    body: String = "Ada pengingat baru untukmu."
  ): PendingIntent {
    if (mode == "Loud Alarm" || mode == "Fullscreen Alert" || mode == "Fake Call") {
      return popupActivityPendingIntent(id, mode, title, body)
    }
    return popupBroadcastPendingIntent(id, mode, title, body)
  }

  private fun popupBroadcastPendingIntent(
    id: Int,
    mode: String = "Loud Alarm",
    title: String = "Reminder",
    body: String = "Ada pengingat baru untukmu."
  ): PendingIntent {
    val intent = Intent(this, ReminderPopupAlarmReceiver::class.java).apply {
      action = "com.nara.app.POPUP_REMINDER_ALARM"
      putExtra("reminder_id", id)
      putExtra("mode", mode)
      putExtra("title", title)
      putExtra("body", body)
    }
    val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
    return PendingIntent.getBroadcast(this, id, intent, flags)
  }

  private fun popupActivityPendingIntent(
    id: Int,
    mode: String = "Loud Alarm",
    title: String = "Reminder",
    body: String = "Ada pengingat baru untukmu."
  ): PendingIntent {
    val intent = Intent(this, AlarmAlertActivity::class.java).apply {
      flags = Intent.FLAG_ACTIVITY_NEW_TASK or
          Intent.FLAG_ACTIVITY_SINGLE_TOP or
          Intent.FLAG_ACTIVITY_CLEAR_TOP
      putExtra("from_popup_alarm", true)
      putExtra("reminder_id", id)
      putExtra("mode", mode)
      putExtra("title", title)
      putExtra("body", body)
    }
    val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
    return PendingIntent.getActivity(this, id, intent, flags)
  }

  private fun relayPopupAlarmFromIntent(intent: Intent?) {
    if (intent?.getBooleanExtra("from_popup_alarm", false) != true) return
    val reminderId = intent.getIntExtra("reminder_id", -1)
    if (reminderId < 0) return
    val action = intent.getStringExtra("popup_action")
    latestPopupReminderId = reminderId

    val channel = popupChannel
    if (channel == null) {
      pendingPopupReminderId = reminderId
      if (!action.isNullOrBlank()) {
        pendingPopupAction = mapOf("id" to reminderId, "action" to action)
      }
      return
    }

    if (!action.isNullOrBlank()) {
      channel.invokeMethod(
        "onPopupAlarmAction",
        mapOf("id" to reminderId, "action" to action)
      )
      return
    }

    channel.invokeMethod("onPopupAlarmTriggered", mapOf("id" to reminderId))
  }

  private fun flushPendingPopupReminder() {
    val reminderId = pendingPopupReminderId ?: return
    val channel = popupChannel ?: return
    latestPopupReminderId = reminderId
    channel.invokeMethod(
      "onPopupAlarmTriggered",
      mapOf("id" to reminderId)
    )
    pendingPopupReminderId = null
  }

  private fun flushPendingPopupAction() {
    val actionPayload = pendingPopupAction ?: return
    val channel = popupChannel ?: return
    channel.invokeMethod("onPopupAlarmAction", actionPayload)
    pendingPopupAction = null
  }

  private fun openReminderSystemSettings(target: String) {
    val intent = when (target) {
      "notification" -> Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
        putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
      }
      "exact_alarm" -> Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
        data = Uri.parse("package:$packageName")
      }
      "fullscreen" -> {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
          Intent(Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT).apply {
            data = Uri.parse("package:$packageName")
          }
        } else {
          Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
            data = Uri.parse("package:$packageName")
          }
        }
      }
      "battery" -> Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
        data = Uri.parse("package:$packageName")
      }
      else -> Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
        data = Uri.parse("package:$packageName")
      }
    }

    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    try {
      startActivity(intent)
    } catch (_: Exception) {
      val fallback = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
        data = Uri.parse("package:$packageName")
        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
      }
      startActivity(fallback)
    }
  }
}
