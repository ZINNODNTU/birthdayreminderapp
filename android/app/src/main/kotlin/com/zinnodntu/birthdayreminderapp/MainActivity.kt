package com.zinnodntu.birthdayreminderapp

import android.content.Intent
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "birthday_reminder/settings"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Register custom plugin for APK installation
        flutterEngine.plugins.add(ApkInstallerPlugin())

        // Existing settings channel
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "openAppNotificationSettings" -> {
                    try {
                        val intent = Intent(
                            Settings.ACTION_APP_NOTIFICATION_SETTINGS,
                        ).apply {
                            putExtra(
                                Settings.EXTRA_APP_PACKAGE,
                                packageName,
                            )
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Throwable) {
                        result.error("OPEN_SETTINGS_FAILED", e.message, null)
                    }
                }
                "openExactAlarmSettings" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            val intent = Intent(
                                Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM,
                            ).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(true)
                        } else {
                            result.success(false)
                        }
                    } catch (e: Throwable) {
                        result.error("OPEN_EXACT_ALARM_FAILED", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}