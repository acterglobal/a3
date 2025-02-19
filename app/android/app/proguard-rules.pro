# Flutter Wrapper
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# FIX for: ERROR: R8: Library class android.content.res.XmlResourceParser implements program class org.xmlpull.v1.XmlPullParser
-dontwarn org.xmlpull.v1.**
-dontwarn org.kxml2.io.**
-dontwarn android.content.res.**
-dontwarn org.slf4j.impl.StaticLoggerBinder
-keep class org.xmlpull.** { *; }
-keepclassmembers class org.xmlpull.** { *; }

# Retain generic signatures of TypeToken and its subclasses with R8 version 3.0 and higher.
# FIX for Notifications Plugin #2547: "RuntimeException: Missing type parameter."
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken

# -keep class io.flutter.app.** { *; }
# -keep class io.flutter.**  { *; }
# --- /end fix

# ---- Specific plugins:
# Firebase for notifications
-keep class com.google.firebase.** { *; }
# Device Calendar fix 
# see https://github.com/builttoroam/device_calendar/issues/99
-keep class com.builttoroam.devicecalendar.** { *; }