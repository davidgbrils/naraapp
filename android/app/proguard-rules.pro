# Keep Flutter plugin registrants
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.engine.plugins.** { *; }

# Keep notification classes used by flutter_local_notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Preserve annotation/runtime metadata commonly used by Kotlin/JSON reflection
-keepattributes *Annotation*
-keepattributes Signature
