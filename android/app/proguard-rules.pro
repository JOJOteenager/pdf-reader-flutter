# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Syncfusion PDF Viewer
-keep class com.syncfusion.** { *; }
-dontwarn com.syncfusion.**

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}
