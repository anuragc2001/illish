package com.anuragchak.illish

import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ResolveInfo
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.anuragchak.illish/upi"
    private val UPI_REQUEST_CODE = 123
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getInstalledUpiApps" -> {
                    result.success(getInstalledUpiApps())
                }
                "launchUpiApp" -> {
                    val packageName = call.argument<String>("packageName")
                    if (packageName != null) {
                        pendingResult = result
                        launchUpiApp(packageName)
                    } else {
                        result.error("INVALID_ARGS", "Missing packageName or uri", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun getInstalledUpiApps(): List<Map<String, Any>> {
        val intent = Intent(Intent.ACTION_VIEW)
        intent.data = Uri.parse("upi://pay")
        
        val apps = mutableListOf<Map<String, Any>>()
        val pm: PackageManager = packageManager
        
        val resolveInfoList: List<ResolveInfo> = if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
            pm.queryIntentActivities(intent, PackageManager.ResolveInfoFlags.of(PackageManager.MATCH_DEFAULT_ONLY.toLong()))
        } else {
            @Suppress("DEPRECATION")
            pm.queryIntentActivities(intent, PackageManager.MATCH_DEFAULT_ONLY)
        }

        for (resolveInfo in resolveInfoList) {
            val packageName = resolveInfo.activityInfo.packageName
            val name = resolveInfo.loadLabel(pm).toString()
            val iconDrawable = resolveInfo.loadIcon(pm)
            
            val iconBytes = drawableToByteArray(iconDrawable)
            
            val appInfo = mapOf(
                "packageName" to packageName,
                "name" to name,
                "icon" to iconBytes
            )
            apps.add(appInfo)
        }
        
        return apps
    }
    
    private fun drawableToByteArray(drawable: Drawable): ByteArray {
        val bitmap = if (drawable is BitmapDrawable) {
            drawable.bitmap
        } else {
            val bmp = Bitmap.createBitmap(
                drawable.intrinsicWidth.takeIf { it > 0 } ?: 1,
                drawable.intrinsicHeight.takeIf { it > 0 } ?: 1,
                Bitmap.Config.ARGB_8888
            )
            val canvas = Canvas(bmp)
            drawable.setBounds(0, 0, canvas.width, canvas.height)
            drawable.draw(canvas)
            bmp
        }
        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
        return stream.toByteArray()
    }

    private fun launchUpiApp(packageName: String) {
        try {
            val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
            if (launchIntent != null) {
                startActivity(launchIntent)
                pendingResult?.success(mapOf("status" to "SUCCESS", "rawResponse" to "App launched successfully"))
            } else {
                pendingResult?.error("LAUNCH_FAILED", "Could not find launch intent for $packageName", null)
            }
        } catch (e: Exception) {
            pendingResult?.error("LAUNCH_FAILED", e.message, null)
        }
        pendingResult = null
    }
}
