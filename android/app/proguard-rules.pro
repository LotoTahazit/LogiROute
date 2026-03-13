# ✅ ProGuard Rules для LogiRoute

# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# Firebase Core
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Firebase Auth
-keep class com.google.firebase.auth.** { *; }
-keepclassmembers class com.google.firebase.auth.** { *; }

# Firestore
-keep class com.google.firebase.firestore.** { *; }
-keepclassmembers class com.google.firebase.firestore.** { *; }
-keep class com.google.protobuf.** { *; }

# Google Maps
-keep class com.google.android.gms.maps.** { *; }
-keep interface com.google.android.gms.maps.** { *; }

# Geolocator
-keep class com.baseflow.geolocator.** { *; }

# SharedPreferences
-keep class androidx.preference.** { *; }

# Gson (используется в Firebase)
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# OkHttp (для HTTP запросов)
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }

# PDF и Printing
-keep class android.print.** { *; }

# Google Play Core (игнорируем отсутствующие классы - не используем Play Store)
# Flutter требует эти классы, но они не нужны для прямой установки APK
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# InputMethodManager fixes
-keep class androidx.core.view.inputmethod.** { *; }
-keep class android.view.inputmethod.InputMethodManager { *; }
-dontwarn androidx.core.view.inputmethod.**

# Flutter text input
-keep class io.flutter.plugin.editing.** { *; }
-dontwarn io.flutter.plugin.editing.**

