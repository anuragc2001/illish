# WorkManager and Room rules to prevent R8 from stripping their classes during release builds
-keep class androidx.work.** { *; }
-keep class androidx.room.** { *; }
-keep class androidx.startup.** { *; }
