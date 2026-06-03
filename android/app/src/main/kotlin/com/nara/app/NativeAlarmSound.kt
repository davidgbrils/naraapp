package com.nara.app

import android.content.Context
import android.media.AudioAttributes
import android.media.Ringtone
import android.media.RingtoneManager
import android.os.Build
import android.util.Log

object NativeAlarmSound {
  private const val TAG = "NativeAlarmSound"
  private var ringtone: Ringtone? = null

  @Synchronized
  fun start(context: Context, mode: String = "Loud Alarm") {
    stop()
    try {
      val soundUri = if (mode == "Fake Call") {
        RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
      } else {
        RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
      }
      ringtone = RingtoneManager.getRingtone(context.applicationContext, soundUri)
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
      Log.i(TAG, "alarm sound started mode=$mode")
    } catch (e: Exception) {
      Log.e(TAG, "failed to start alarm sound", e)
      ringtone = null
    }
  }

  @Synchronized
  fun stop() {
    try {
      ringtone?.stop()
    } catch (e: Exception) {
      Log.e(TAG, "failed to stop alarm sound", e)
    } finally {
      ringtone = null
    }
  }
}
