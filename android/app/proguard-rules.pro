# RecallSentry Flutter App - ProGuard Rules
# Generated: 2025-01-16
# Purpose: Optimize APK size while preserving Flutter functionality

# ================================
# Flutter Framework
# ================================
# Keep Flutter wrapper classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ================================
# Firebase
# ================================
# Keep Firebase classes for push notifications
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Firebase Messaging
-keep class com.google.firebase.messaging.** { *; }
-keep class com.google.firebase.iid.** { *; }

# ================================
# SQLite (sqflite plugin)
# ================================
# Keep SQLite classes for offline database support
-keep class io.flutter.plugins.sqflite.** { *; }
-keep class org.sqlite.** { *; }
-dontwarn org.sqlite.**

# ================================
# Secure Storage
# ================================
# Keep secure storage plugin classes
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# ================================
# HTTP & Networking
# ================================
# Keep HTTP client classes
-keep class io.flutter.plugins.urllauncher.** { *; }
-keepattributes Signature
-keepattributes *Annotation*

# ================================
# JSON Serialization
# ================================
# Keep Gson classes if using JSON serialization
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*

# Keep model classes (adjust package name as needed)
# Uncomment and modify if you have model classes that use reflection
# -keep class com.example.rs_flutter.models.** { *; }

# ================================
# General Android
# ================================
# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep custom views
-keepclasseswithmembers class * {
    public <init>(android.content.Context, android.util.AttributeSet);
}

# Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep Parcelable classes
-keep class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

# Keep serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# ================================
# Debugging & Logging
# ================================
# Remove debug logging in release builds
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int d(...);
    public static int i(...);
    public static int w(...);
    public static int e(...);
}

# ================================
# Optimization Settings
# ================================
# Enable aggressive optimizations
-optimizationpasses 5
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-verbose

# Optimization options
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*

# ================================
# Crashlytics (if using Firebase Crashlytics)
# ================================
# Uncomment if you use Firebase Crashlytics
# -keepattributes SourceFile,LineNumberTable
# -keep public class * extends java.lang.Exception

# ================================
# Additional Plugin Rules
# ================================
# Add rules for any additional Flutter plugins you use
# Check each plugin's documentation for specific ProGuard rules
