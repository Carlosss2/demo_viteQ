package com.example.app_demo

import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.app_demo/fake_gps"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            if (call.method == "isMockLocationEnabled") {
                result.success(isMockLocationEnabled())
            } else {
                result.notImplemented()
            }
        }
    }

    private fun isMockLocationEnabled(): Boolean {
        return try {
            @Suppress("DEPRECATION")
            Settings.Secure.getInt(
                contentResolver,
                Settings.Secure.ALLOW_MOCK_LOCATION,
                0
            ) == 1
        } catch (e: Exception) {
            false
        }
    }
}
