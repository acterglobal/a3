# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# ---- Specific plugins:
# Firebase for notifications
-keep class com.google.firebase.** { *; }
# Device Calendar fix 
# see https://github.com/builttoroam/device_calendar/issues/99
-keep class com.builttoroam.devicecalendar.** { *; }