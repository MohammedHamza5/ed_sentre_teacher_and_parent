# ================================================
# EdSentre Teacher & Parent — ProGuard / R8 Rules
# ================================================
# Flutter يتعامل مع الكثير تلقائياً، هذه القواعد لمكتبات الطرف الثالث

# ── Flutter ──────────────────────────────────────
-keep class io.flutter.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.**

# ── Firebase ──────────────────────────────────────
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# ── Supabase / Ktor / OkHttp ──────────────────────
-keep class io.ktor.** { *; }
-dontwarn io.ktor.**
-keep class okhttp3.** { *; }
-dontwarn okhttp3.**
-keep class okio.** { *; }
-dontwarn okio.**

# ── Kotlin Serialization ──────────────────────────
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.AnnotationsKt
-keepclassmembers class kotlinx.serialization.json.** { *** Companion; }
-keepclasseswithmembers class kotlinx.serialization.** { kotlinx.serialization.KSerializer serializer(...); }

# ── Hive ──────────────────────────────────────────
-keep class com.hivemq.** { *; }
-dontwarn com.hivemq.**

# ── Coroutines ────────────────────────────────────
-keepnames class kotlinx.coroutines.internal.MainDispatcherFactory {}
-keepnames class kotlinx.coroutines.CoroutineExceptionHandler {}
-dontwarn kotlinx.coroutines.**

# ── Shorebird ─────────────────────────────────────
-keep class com.shorebird.** { *; }
-dontwarn com.shorebird.**

# ── General ───────────────────────────────────────
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
-keep public class * extends java.lang.Exception
