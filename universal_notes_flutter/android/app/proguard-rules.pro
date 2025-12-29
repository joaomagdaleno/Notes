# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Google Play Services & Firebase
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Guava (Common cause of R8 issues)
-keep class com.google.common.** { *; }
-dontwarn com.google.common.**
-dontwarn com.google.errorprone.annotations.**
-dontwarn org.checkerframework.**

# OpenTelemetry
-keep class io.opentelemetry.** { *; }
-dontwarn io.opentelemetry.**

# Play Core (referenced by Flutter but not always included)
-dontwarn com.google.android.play.core.**

# gRPC / OkHttp (grpc-okhttp references legacy OkHttp classes)
-dontwarn com.squareup.okhttp.**
-dontwarn io.grpc.okhttp.**

# General R8/ProGuard Rules
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-keepattributes SourceFile,LineNumberTable

# Retain generic type information for reflection
-keepattributes Signature
