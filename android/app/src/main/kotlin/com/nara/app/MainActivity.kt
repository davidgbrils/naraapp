package com.nara.app

import android.Manifest
import android.app.AlarmManager
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.PowerManager
import android.provider.Settings
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
  private val tag = "MainActivity"
  private val popupAlarmChannel = "nara/reminder_popup_alarm"
  private val wakeWordChannelName = "nara/wake_word"
  private val startupPermissionChannelName = "nara/startup_permissions"
  private val startupPermissionRequestCode = 7101
  private val alarmStatePrefs = "nara_alarm_state"
  private val completedAlarmIdsKey = "completed_popup_alarm_ids"
  private var popupChannel: MethodChannel? = null
  private var wakeWordChannel: MethodChannel? = null
  private var startupPermissionChannel: MethodChannel? = null
  private var pendingPopupReminderId: Int? = null
  private var latestPopupReminderId: Int? = null
  private var pendingPopupAction: Map<String, Any?>? = null
  private var pendingWakeWordDetected: Boolean = false

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)
    popupChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, popupAlarmChannel)
    wakeWordChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, wakeWordChannelName)
    startupPermissionChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, startupPermissionChannelName)
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
    wakeWordChannel
      ?.setMethodCallHandler { call, result ->
        when (call.method) {
          "startWakeWordService" -> {
            result.success(startWakeWordService())
          }
          "stopWakeWordService" -> {
            result.success(stopWakeWordService())
          }
          "isWakeWordServiceRunning" -> {
            result.success(WakeWordForegroundService.isRunning)
          }
          "consumePendingWakeWord" -> {
            val pending = pendingWakeWordDetected
            pendingWakeWordDetected = false
            result.success(pending)
          }
          else -> result.notImplemented()
        }
      }
    startupPermissionChannel
      ?.setMethodCallHandler { call, result ->
        when (call.method) {
          "requestRuntimePermissions" -> {
            requestStartupRuntimePermissions()
            result.success(true)
          }
          else -> result.notImplemented()
        }
      }
    flushPendingPopupReminder()
    flushPendingPopupAction()
    flushPendingWakeWord()
    relayPopupAlarmFromIntent(intent)
    relayWakeWordFromIntent(intent)
  }

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    relayPopupAlarmFromIntent(intent)
    relayWakeWordFromIntent(intent)
  }

  override fun onNewIntent(intent: Intent) {
    super.onNewIntent(intent)
    setIntent(intent)
    relayPopupAlarmFromIntent(intent)
    relayWakeWordFromIntent(intent)
  }

  private fun schedulePopupAlarm(
    id: Int,
    triggerAtMillis: Long,
    mode: String,
    title: String,
    body: String
  ) {
    clearNativeCompletedAlarm(id)
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
    markNativeCompletedAlarm(id)
    stopNativeAlarmService(id)
  }

  private fun popupPendingIntent(
    id: Int,
    mode: String = "Loud Alarm",
    title: String = "Reminder",
    body: String = "Ada pengingat baru untukmu."
  ): PendingIntent {
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

  private fun relayWakeWordFromIntent(intent: Intent?) {
    if (intent?.getBooleanExtra("from_wake_word", false) != true) return
    pendingWakeWordDetected = true
    val channel = wakeWordChannel
    if (channel == null) {
      return
    }
    channel.invokeMethod(
      "onWakeWordDetected",
      null,
      object : MethodChannel.Result {
        override fun success(result: Any?) {
          pendingWakeWordDetected = false
        }

        override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
          Log.e(tag, "Failed to deliver wake word: $errorCode $errorMessage")
        }

        override fun notImplemented() {}
      }
    )
  }

  private fun flushPendingWakeWord() {
    if (!pendingWakeWordDetected) return
    val channel = wakeWordChannel ?: return
    channel.invokeMethod(
      "onWakeWordDetected",
      null,
      object : MethodChannel.Result {
        override fun success(result: Any?) {
          pendingWakeWordDetected = false
        }

        override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) {
          Log.e(tag, "Failed to flush wake word: $errorCode $errorMessage")
        }

        override fun notImplemented() {}
      }
    )
  }

  private fun startWakeWordService(): Boolean {
    val intent = Intent(this, WakeWordForegroundService::class.java).apply {
      action = WakeWordForegroundService.ACTION_START
    }
    return try {
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
        startForegroundService(intent)
      } else {
        startService(intent)
      }
      true
    } catch (exception: Exception) {
      Log.e(tag, "Failed to start wake word service", exception)
      false
    }
  }

  private fun stopWakeWordService(): Boolean {
    val intent = Intent(this, WakeWordForegroundService::class.java).apply {
      action = WakeWordForegroundService.ACTION_STOP
    }
    return try {
      startService(intent)
      true
    } catch (exception: Exception) {
      Log.e(tag, "Failed to stop wake word service", exception)
      false
    }
  }

  private fun markNativeCompletedAlarm(id: Int) {
    val prefs = getSharedPreferences(alarmStatePrefs, Context.MODE_PRIVATE)
    val ids = prefs.getStringSet(completedAlarmIdsKey, emptySet())?.toMutableSet()
      ?: mutableSetOf()
    ids.add(id.toString())
    prefs.edit().putStringSet(completedAlarmIdsKey, ids).apply()
  }

  private fun clearNativeCompletedAlarm(id: Int) {
    val prefs = getSharedPreferences(alarmStatePrefs, Context.MODE_PRIVATE)
    val ids = prefs.getStringSet(completedAlarmIdsKey, emptySet())?.toMutableSet()
      ?: mutableSetOf()
    if (ids.remove(id.toString())) {
      prefs.edit().putStringSet(completedAlarmIdsKey, ids).apply()
    }
  }

  private fun stopNativeAlarmService(id: Int) {
    NativeAlarmSound.stop()
    val stopIntent = Intent(this, AlarmForegroundService::class.java).apply {
      action = AlarmForegroundService.ACTION_STOP
      putExtra("reminder_id", id)
    }
    try {
      startService(stopIntent)
    } catch (_: Exception) {}
  }

  private fun requestStartupRuntimePermissions() {
    val permissions = mutableListOf<String>()
    if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
      permissions.add(Manifest.permission.RECORD_AUDIO)
    }
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
      ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED
    ) {
      permissions.add(Manifest.permission.POST_NOTIFICATIONS)
    }
    if (permissions.isNotEmpty()) {
      ActivityCompat.requestPermissions(this, permissions.toTypedArray(), startupPermissionRequestCode)
    }
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
