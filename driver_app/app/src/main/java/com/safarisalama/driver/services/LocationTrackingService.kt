package com.safarisalama.driver.services

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log

class LocationTrackingService : Service() {

    private val CHANNEL_ID = "LocationServiceChannel"

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d("LocationTrackingService", "Service started")
        
        val notification: Notification = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
                .setContentTitle("Safari Salama Tracking Active")
                .setContentText("Your location is being shared with passengers.")
                //.setSmallIcon(R.drawable.ic_launcher_foreground) // Make sure to add this drawable
                .build()
        } else {
            Notification.Builder(this)
                .setContentTitle("Safari Salama Tracking Active")
                .setContentText("Your location is being shared with passengers.")
                .build()
        }

        startForeground(1, notification)
        
        // TODO: Initialize FusedLocationProviderClient here
        // TODO: Start location requests and send updates to WebSockets/API

        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d("LocationTrackingService", "Service destroyed")
        // TODO: Stop location requests and close WebSocket
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                CHANNEL_ID,
                "Safari Salama Tracking Channel",
                NotificationManager.IMPORTANCE_DEFAULT
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(serviceChannel)
        }
    }
}
