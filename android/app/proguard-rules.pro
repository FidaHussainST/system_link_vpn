# Disable R8 obfuscation completely for VPN - simplest solution
-dontshrink
-dontoptimize
-dontobfuscate

# Keep WireGuard classes
-keep class app.wachu.wireguard_vpn.** {*;}
-keep class com.wireguard.** {*;}
-keep interface com.wireguard.** {*;}

# Keep javax.annotation classes (required by WireGuard)
-keep class javax.annotation.** {*;}
-keep class javax.annotation.meta.** {*;}

# Keep all enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep View constructors (needed for inflation)
-keepclasseswithmembers class * {
    public <init>(android.content.Context, android.util.AttributeSet);
}

# Keep onCreate, onDestroy and other lifecycle methods
-keepclasseswithmembernames class * {
    void onCreate(**);
    void onDestroy();
    void onStart();
    void onStop();
}

# Keep all R classes
-keepclassmembers class **.R$* {
    public static <fields>;
}

# Preserve line numbers for debugging
-keepattributes SourceFile,LineNumberTable
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Keep exceptions
-keep public class * extends java.lang.Exception

# Keep all serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep Flutter classes
-keep class io.flutter.** {*;}
-keep class io.flutter.embedding.** {*;}
-keep interface io.flutter.** {*;}