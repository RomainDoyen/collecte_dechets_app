package com.example.collecte_dechets_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "notiwaste/chip_notifications",
        ).setMethodCallHandler { call, result ->
            if (call.method == "show") {
                val id = (call.argument<Number>("id") ?: 0).toInt()
                val typeName = call.argument<String>("typeName").orEmpty()
                val body = call.argument<String>("body").orEmpty()
                CollectionNotificationHelper.show(applicationContext, id, typeName, body)
                result.success(null)
            } else {
                result.notImplemented()
            }
        }
    }
}
