// Frida script to bypass USB Debugging detection in the Flutter app
// Objetivo: hookear el método isUsbDebugEnabled en Kotlin para que siempre retorne false

Java.perform(function () {
    console.log("[*] Frida script loaded - Bypassing USB Debugging detection");

    var MainActivity = Java.use("com.example.secure_app_demo.MainActivity");

    MainActivity.isUsbDebugEnabled.implementation = function () {
        console.log("[*] isUsbDebugEnabled() called - RETURNING FALSE (bypassed)");
        return false;
    };

    console.log("[*] Hook installed on MainActivity.isUsbDebugEnabled");
});
