# Keep Flutter & plugins working with R8/Proguard.
# Flutter's tooling automatically supplies many keep rules, but we add a minimal safe set.

-keep class io.flutter.** { *; }
-dontwarn io.flutter.embedding.**

# Firebase Messaging / Analytics / core
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Kotlin metadata (safe)
-keep class kotlin.Metadata { *; }

