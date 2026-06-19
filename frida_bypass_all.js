// Frida script - Bypass all RASP layers for the SecureApp Demo
// Hooks multiple levels: MethodChannel, Kotlin native, and Dart

'use strict';

// === LAYER 1: Hook the Kotlin native method ===
Java.perform(function () {
    console.log("[*] Layer 1: Hooking Kotlin native method");

    try {
        var MainActivity = Java.use("com.example.secure_app_demo.MainActivity");
        MainActivity.isUsbDebugEnabled.implementation = function () {
            console.log("[*] → isUsbDebugEnabled() = false (hooked)");
            return false;
        };
        console.log("[*] ✓ Kotlin hook installed");
    } catch (e) {
        console.log("[!] Kotlin hook failed: " + e);
    }
});

// === LAYER 2: Hook Settings.Global directly (deeper) ===
Java.perform(function () {
    console.log("[*] Layer 2: Hooking Settings.Global.getInt");

    try {
        var SettingsGlobal = Java.use("android.provider.Settings$Global");
        SettingsGlobal.getInt.overload('android.content.ContentResolver', 'java.lang.String', 'int').implementation = function (resolver, name, def) {
            if (name === "adb_enabled") {
                console.log("[*] → Settings.Global.getInt('adb_enabled') = 0 (hooked)");
                return 0;
            }
            return this.getInt(resolver, name, def);
        };
        console.log("[*] ✓ Settings.Global hook installed");
    } catch (e) {
        console.log("[!] Settings.Global hook failed: " + e);
    }
});

console.log("[*] All hooks installed. App should now load normally.");
