package com.example.mileage_calculator

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "fuelbhai/foreground_service"
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startForeground" -> {
                    startForegroundService()
                    result.success(null)
                }
                "stopForeground" -> {
                    stopForegroundService()
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    private fun startForegroundService() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceIntent = Intent(this, TripForegroundService::class.java)
            startForegroundService(serviceIntent)
        } else {
            val serviceIntent = Intent(this, TripForegroundService::class.java)
            startService(serviceIntent)
        }
    }
    
    private fun stopForegroundService() {
        val serviceIntent = Intent(this, TripForegroundService::class.java)
        stopService(serviceIntent)
    }
}
