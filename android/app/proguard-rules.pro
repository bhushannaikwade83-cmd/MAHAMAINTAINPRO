# Keep Flutter's own embedding classes.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase Messaging / Analytics - reflection-based, breaks silently if
# stripped/renamed by R8.
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Razorpay checkout uses reflection to read these model classes.
-keep class com.razorpay.** { *; }
-keep class proguard.annotation.Keep { *; }
-keep class proguard.annotation.KeepClassMembers { *; }
-keepclassmembers class * {
  @proguard.annotation.Keep *;
}
-keepclasseswithmembers class * {
  @proguard.annotation.KeepClassMembers *;
}
-dontwarn com.razorpay.**
-optimizations !method/inlining/*
-keepattributes *Annotation*

# Geolocator plugin
-keep class com.baseflow.geolocator.** { *; }
-dontwarn com.baseflow.geolocator.**

# google_maps_flutter
-keep class com.google.maps.** { *; }
-dontwarn com.google.maps.**

# Google Play Core - for split delivery / deferred components
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**
