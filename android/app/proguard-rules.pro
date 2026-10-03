# Flutter ProGuard Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Play Core & Split Compat (Deferred Components)
-dontwarn com.google.android.play.core.**

# Background service & notifications
-keep class id.flutter.flutter_background_service.** { *; }
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Geolocator & Permissions
-keep class com.baseflow.geolocator.** { *; }
-keep class com.baseflow.permissionhandler.** { *; }

# Device Info
-keep class dev.fluttercommunity.plus.device_info.** { *; }

# Razorpay SDK
-keepattributes *Annotation*
-dontwarn com.razorpay.**
-keep class com.razorpay.** { *; }
-optimizations !class/merging/vertical*,!class/merging/horizontal*
-keepattributes InnerClasses
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Firebase & Google Services
-dontwarn com.google.android.gms.**
-keep class com.google.android.gms.** { *; }
-keep class com.google.firebase.** { *; }
