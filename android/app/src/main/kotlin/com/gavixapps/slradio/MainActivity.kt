package com.gavixapps.slradio

import android.content.Intent
import android.net.Uri
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.gavixapps.slradio/permissions").setMethodCallHandler { call, result ->
            if (call.method == "grantUriPermission") {
                val uriString = call.argument<String>("uri")
                if (uriString != null) {
                    try {
                        val uri = Uri.parse(uriString)
                        val packages = listOf(
                            "com.google.android.projection.gearhead",
                            "com.google.android.googlequicksearchbox",
                            "com.google.android.apps.auto.carservice"
                        )
                        for (pkg in packages) {
                            applicationContext.grantUriPermission(
                                pkg,
                                uri,
                                Intent.FLAG_GRANT_READ_URI_PERMISSION
                            )
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                } else {
                    result.error("BAD_ARGS", "Missing URI", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
