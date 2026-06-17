package com.example.app_demo

import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.File
import java.io.FileReader
import java.net.Socket

class MainActivity : FlutterActivity() {
    private val FAKE_GPS_CHANNEL = "com.example.app_demo/fake_gps"
    private val USB_DEBUG_CHANNEL = "com.example.app_demo/usb_debug"
    private val INTEGRITY_CHANNEL = "com.example.app_demo/integrity"

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

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            INTEGRITY_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isFridaDetected" -> result.success(isFridaDetected())
                "isRootDetected" -> result.success(isRootDetected())
                "isIntegrityCompromised" -> result.success(isFridaDetected() || isRootDetected())
                else -> result.notImplemented()
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

    private fun isFridaDetected(): Boolean {
        return isFridaOnMaps() || isFridaPortOpen() || isFridaPipePresent() || isFridaProcessRunning()
    }

    private fun isFridaOnMaps(): Boolean {
        return try {
            val reader = BufferedReader(FileReader("/proc/self/maps"))
            val content = reader.readText()
            reader.close()
            content.contains("frida")
        } catch (e: Exception) {
            false
        }
    }

    private fun isFridaPortOpen(): Boolean {
        return try {
            val socket = Socket("127.0.0.1", 27042)
            socket.close()
            true
        } catch (e: Exception) {
            try {
                val socket = Socket("127.0.0.1", 27043)
                socket.close()
                true
            } catch (e2: Exception) {
                false
            }
        }
    }

    private fun isFridaPipePresent(): Boolean {
        return try {
            val pipeFile = File("/data/local/tmp/frida-server")
            pipeFile.exists()
        } catch (e: Exception) {
            false
        }
    }

    private fun isFridaProcessRunning(): Boolean {
        return try {
            val process = Runtime.getRuntime().exec(arrayOf("ps", "-A"))
            val reader = BufferedReader(FileReader("/proc/self/status"))
            val reader2 = BufferedReader(FileReader("/proc/self/status"))
            val output = process.inputStream.bufferedReader().readText()
            process.waitFor()
            output.contains("frida")
        } catch (e: Exception) {
            false
        }
    }

    private fun isRootDetected(): Boolean {
        return isSuBinaryPresent() || isRootedByBuildTags() || hasRootPermissions()
    }

    private fun isSuBinaryPresent(): Boolean {
        val suPaths = arrayOf(
            "/system/app/Superuser.apk",
            "/sbin/su",
            "/system/bin/su",
            "/system/xbin/su",
            "/data/local/xbin/su",
            "/data/local/bin/su",
            "/system/sd/xbin/su",
            "/system/bin/failsafe/su",
            "/data/local/su",
            "/su/bin/su"
        )
        return suPaths.any { path -> File(path).exists() }
    }

    private fun isRootedByBuildTags(): Boolean {
        val tags = Build.TAGS
        return tags != null && tags.contains("test-keys")
    }

    private fun hasRootPermissions(): Boolean {
        return try {
            val process = Runtime.getRuntime().exec(arrayOf("su", "-c", "id"))
            val reader = BufferedReader(process.inputStream.reader())
            val output = reader.readText()
            process.waitFor()
            output.contains("uid=0")
        } catch (e: Exception) {
            false
        }
    }
}
