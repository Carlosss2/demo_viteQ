# Flutter ProGuard / R8 Rules
# ============================
# Estas reglas evitan que R8 elimine u ofusque clases necesarias
# para el correcto funcionamiento de Flutter y sus plugins.

# Flutter engine classes must be kept
-keep class io.flutter.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.app.** { *; }

# Keep all native (JNI) methods used by Flutter
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep all methods annotated with @Keep
-keep,allowobfuscation class * {
    @androidx.annotation.Keep <methods>;
}

# Keep the MainActivity entry point
-keep class com.example.secure_app_demo.MainActivity { *; }

# Keep FlutterPluginRegistrant
-keep class io.flutter.plugins.** { *; }

# Keep generic signatures for proper JSON/reflection
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep R8 from stripping Flutter's engine classes
-dontwarn io.flutter.**
-dontwarn com.google.auto.value.**
