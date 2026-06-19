package com.example.secure_app_demo

import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val USB_DEBUG_CHANNEL = "com.example.secure_app_demo/usb_debug"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            USB_DEBUG_CHANNEL
        ).setMethodCallHandler { call, result ->
            if (call.method == "isUsbDebugEnabled") {
                result.success(isUsbDebugEnabled())
            } else {
                result.notImplemented()
            }
        }
    }

    private fun isUsbDebugEnabled(): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1) {
                Settings.Global.getInt(
                    contentResolver,
                    Settings.Global.ADB_ENABLED,
                    0
                ) == 1
            } else {
                false
            }
        } catch (e: Exception) {
            false
        }
    }
}
