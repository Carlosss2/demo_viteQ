package com.example.app_demo

import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val FAKE_GPS_CHANNEL = "com.example.app_demo/fake_gps"
    private val USB_DEBUG_CHANNEL = "com.example.app_demo/usb_debug"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            FAKE_GPS_CHANNEL
        ).setMethodCallHandler { call, result ->
            if (call.method == "isMockLocationEnabled") {
                result.success(isMockLocationEnabled())
            } else {
                result.notImplemented()
            }
        }

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

    private fun isMockLocationEnabled(): Boolean {
        return isEmulator() || isMockLocationSettingEnabled()
    }

    private fun isEmulator(): Boolean {
        return (Build.BRAND.startsWith("generic") && Build.DEVICE.startsWith("generic")) ||
                Build.FINGERPRINT.startsWith("generic") ||
                Build.FINGERPRINT.startsWith("unknown") ||
                Build.MODEL.contains("google_sdk") ||
                Build.MODEL.contains("Emulator") ||
                Build.MODEL.contains("Android SDK built for x86") ||
                Build.MANUFACTURER.contains("Genymotion") ||
                Build.HARDWARE.contains("goldfish") ||
                Build.HARDWARE.contains("ranchu") ||
                Build.PRODUCT.contains("sdk") ||
                Build.PRODUCT.contains("vbox86p") ||
                Build.PRODUCT.contains("emulator") ||
                Build.PRODUCT.contains("simulator")
    }

    @Suppress("DEPRECATION")
    private fun isMockLocationSettingEnabled(): Boolean {
        return try {
            Settings.Secure.getInt(
                contentResolver,
                Settings.Secure.ALLOW_MOCK_LOCATION,
                0
            ) == 1
        } catch (e: Exception) {
            false
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
