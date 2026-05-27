package com.nara.app

import android.app.Activity
import android.app.AlarmManager
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.media.Ringtone
import android.media.RingtoneManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

class AlarmAlertActivity : Activity() {
  private var reminderId: Int = -1
  private var mode: String = "Loud Alarm"
  private var title: String = "Reminder"
  private var body: String = "Ada pengingat baru untukmu."
  private var ringtone: Ringtone? = null
  private val handler = Handler(Looper.getMainLooper())
  private val autoSnoozeRunnable = Runnable {
    handleSnooze()
  }

  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
      setShowWhenLocked(true)
      setTurnScreenOn(true)
    }
    reminderId = intent?.getIntExtra("reminder_id", -1) ?: -1
    if (reminderId < 0) {
      finish()
      return
    }
    mode = intent?.getStringExtra("mode") ?: "Loud Alarm"
    title = intent?.getStringExtra("title") ?: "Reminder"
    body = intent?.getStringExtra("body") ?: "Ada pengingat baru untukmu."

    setContentView(buildContent())
    startAlarmSound()
    handler.postDelayed(autoSnoozeRunnable, autoSnoozeDelayMillis())
  }

  override fun onNewIntent(intent: Intent?) {
    super.onNewIntent(intent)
    setIntent(intent)
  }

  override fun onDestroy() {
    super.onDestroy()
    stopAlarmSound()
    handler.removeCallbacks(autoSnoozeRunnable)
  }

  private fun buildContent(): LinearLayout {
    val language = currentLanguageCode()
    val completeLabel = if (language == "id") "Selesai" else "Complete"
    val snoozeLabel = if (language == "id") "Tunda 5 Menit" else "Snooze 5 Minutes"

    val root = LinearLayout(this).apply {
      orientation = LinearLayout.VERTICAL
      gravity = Gravity.CENTER
      setPadding(48, 72, 48, 72)
      layoutParams = ViewGroup.LayoutParams(
        ViewGroup.LayoutParams.MATCH_PARENT,
        ViewGroup.LayoutParams.MATCH_PARENT
      )
      setBackgroundColor(Color.parseColor("#0B1220"))
    }

    val card = LinearLayout(this).apply {
      orientation = LinearLayout.VERTICAL
      gravity = Gravity.CENTER_HORIZONTAL
      val lp = LinearLayout.LayoutParams(
        ViewGroup.LayoutParams.MATCH_PARENT,
        ViewGroup.LayoutParams.WRAP_CONTENT
      )
      layoutParams = lp
      setPadding(36, 44, 36, 28)
      background = GradientDrawable().apply {
        shape = GradientDrawable.RECTANGLE
        cornerRadius = 40f
        setColor(Color.parseColor("#F8FAFC"))
      }
    }

    val badgeView = TextView(this).apply {
      text = mode.uppercase()
      textSize = 11f
      setTextColor(Color.parseColor("#B45309"))
      gravity = Gravity.CENTER
      setPadding(20, 10, 20, 10)
      background = GradientDrawable().apply {
        shape = GradientDrawable.RECTANGLE
        cornerRadius = 999f
        setColor(Color.parseColor("#FEF3C7"))
      }
    }

    val spacerSm = View(this).apply {
      layoutParams = LinearLayout.LayoutParams(
        ViewGroup.LayoutParams.MATCH_PARENT,
        14
      )
    }

    val spacerMd = View(this).apply {
      layoutParams = LinearLayout.LayoutParams(
        ViewGroup.LayoutParams.MATCH_PARENT,
        20
      )
    }

    val titleView = TextView(this).apply {
      text = title
      textSize = 30f
      setTypeface(typeface, Typeface.BOLD)
      setTextColor(Color.parseColor("#111827"))
      gravity = Gravity.CENTER
    }
    val bodyView = TextView(this).apply {
      text = body
      textSize = 16f
      setTextColor(Color.parseColor("#475569"))
      gravity = Gravity.CENTER
    }
    val modeView = TextView(this).apply {
      text = mode
      textSize = 12f
      setTextColor(Color.parseColor("#64748B"))
      gravity = Gravity.CENTER
    }

    val answerButton = Button(this).apply {
      text = completeLabel
      setTextColor(Color.WHITE)
      textSize = 16f
      setTypeface(typeface, Typeface.BOLD)
      background = GradientDrawable().apply {
        shape = GradientDrawable.RECTANGLE
        cornerRadius = 22f
        setColor(Color.parseColor("#2563EB"))
      }
      val lp = LinearLayout.LayoutParams(
        ViewGroup.LayoutParams.MATCH_PARENT,
        ViewGroup.LayoutParams.WRAP_CONTENT
      )
      lp.topMargin = 20
      layoutParams = lp
      setOnClickListener { handleComplete() }
    }
    val snoozeButton = Button(this).apply {
      text = snoozeLabel
      setTextColor(Color.parseColor("#111827"))
      textSize = 15f
      background = GradientDrawable().apply {
        shape = GradientDrawable.RECTANGLE
        cornerRadius = 22f
        setColor(Color.parseColor("#E2E8F0"))
      }
      val lp = LinearLayout.LayoutParams(
        ViewGroup.LayoutParams.MATCH_PARENT,
        ViewGroup.LayoutParams.WRAP_CONTENT
      )
      lp.topMargin = 12
      layoutParams = lp
      setOnClickListener { handleSnooze() }
    }

    card.addView(badgeView)
    card.addView(spacerSm)
    card.addView(titleView)
    card.addView(spacerSm)
    card.addView(bodyView)
    card.addView(spacerMd)
    card.addView(modeView)
    card.addView(answerButton)
    card.addView(snoozeButton)
    root.addView(card)
    return root
  }

  private fun autoSnoozeDelayMillis(): Long {
    return when (mode) {
      "Loud Alarm" -> 90_000L
      "Fullscreen Alert" -> 75_000L
      "Fake Call" -> 60_000L
      else -> 60_000L
    }
  }

  private fun startAlarmSound() {
    val soundUri = if (mode == "Fake Call") {
      RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
    } else {
      RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
    }
    ringtone = RingtoneManager.getRingtone(this, soundUri)
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
      ringtone?.audioAttributes = AudioAttributes.Builder()
        .setUsage(
          if (mode == "Fake Call") AudioAttributes.USAGE_NOTIFICATION_RINGTONE
          else AudioAttributes.USAGE_ALARM
        )
        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
        .build()
    }
    ringtone?.play()
  }

  private fun stopAlarmSound() {
    ringtone?.stop()
    ringtone = null
  }

  private fun handleComplete() {
    stopAlarmSound()
    clearNotification()
    stopAlarmService()
    notifyFlutterAction("complete")
    finishAndRemoveTask()
  }

  private fun handleSnooze() {
    stopAlarmSound()
    clearNotification()
    scheduleNativeSnooze(5 * 60 * 1000L)
    stopAlarmService()
    notifyFlutterAction("snooze")
    finishAndRemoveTask()
  }

  private fun clearNotification() {
    val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    manager.cancel(reminderId)
  }

  private fun scheduleNativeSnooze(delayMillis: Long) {
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
    val showIntent = PendingIntent.getActivity(
      this,
      reminderId + 900000,
      Intent(this, MainActivity::class.java).apply {
        flags = Intent.FLAG_ACTIVITY_NEW_TASK or
            Intent.FLAG_ACTIVITY_SINGLE_TOP or
            Intent.FLAG_ACTIVITY_CLEAR_TOP
        putExtra("from_popup_alarm", true)
        putExtra("reminder_id", reminderId)
      },
      PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
    )
    val clockInfo = AlarmManager.AlarmClockInfo(triggerAt, showIntent)
    alarmManager.setAlarmClock(clockInfo, pendingIntent)
  }

  private fun notifyFlutterAction(action: String) {
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

  private fun stopAlarmService() {
    val stopIntent = Intent(this, AlarmForegroundService::class.java).apply {
      action = AlarmForegroundService.ACTION_STOP
    }
    try {
      startService(stopIntent)
    } catch (_: Exception) {}
  }

  private fun currentLanguageCode(): String {
    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
      resources.configuration.locales[0]?.language ?: "en"
    } else {
      @Suppress("DEPRECATION")
      resources.configuration.locale?.language ?: "en"
    }
  }
}
