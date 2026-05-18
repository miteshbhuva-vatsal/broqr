# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Firebase Messaging
-keep class com.google.firebase.messaging.** { *; }

# Facebook SDK
-keep class com.facebook.** { *; }
-dontwarn com.facebook.**

# Kotlin coroutines
-keepclassmembernames class kotlinx.** {
    volatile <fields>;
}

# Keep Kotlin metadata for reflection
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings { <fields>; }

# OkHttp (used by Firebase)
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn javax.annotation.**

# Dio / Retrofit
-dontwarn retrofit2.**
-keep class retrofit2.** { *; }

# Serialization
-keepattributes *Annotation*, Signature, Exception
-keepattributes EnclosingMethod

# App-specific: keep entry points
-keep class com.digiprop.cpapp.** { *; }
-keep class com.digiprop.cpapp.MainActivity { *; }
