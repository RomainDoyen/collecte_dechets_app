package com.example.collecte_dechets_app

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.widget.RemoteViews
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

object CollectionNotificationHelper {
    const val CHANNEL_ID = "notifications"

    fun show(context: Context, id: Int, typeName: String, body: String) {
        ensureChannel(context)

        val views = RemoteViews(context.packageName, R.layout.notification_collection)
        views.setTextViewText(R.id.notif_chip, typeName)
        views.setInt(R.id.notif_chip, "setBackgroundResource", chipDrawable(typeName))
        views.setTextViewText(R.id.notif_suffix, "demain !")
        views.setTextViewText(R.id.notif_body, body)

        val notification =
            NotificationCompat.Builder(context, CHANNEL_ID)
                .setSmallIcon(R.drawable.ic_notification_recycling)
                .setCustomContentView(views)
                .setCustomBigContentView(views)
                .setStyle(NotificationCompat.DecoratedCustomViewStyle())
                .setContentTitle("$typeName demain !")
                .setContentText(body)
                .setAutoCancel(true)
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .build()

        NotificationManagerCompat.from(context).notify(id, notification)
    }

    private fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = context.getSystemService(NotificationManager::class.java) ?: return
        val channel =
            NotificationChannel(
                CHANNEL_ID,
                "Notifications",
                NotificationManager.IMPORTANCE_HIGH,
            )
        manager.createNotificationChannel(channel)
    }

    private fun chipDrawable(typeName: String): Int {
        return when (typeName) {
            "Poubelle jaune", "Collecte Sélective" -> R.drawable.chip_yellow
            "Déchets Verts", "Déchets Végétaux" -> R.drawable.chip_green
            "Encombrants" -> R.drawable.chip_red
            "Déchets Métalliques" -> R.drawable.chip_blue
            else -> R.drawable.chip_grey
        }
    }
}
