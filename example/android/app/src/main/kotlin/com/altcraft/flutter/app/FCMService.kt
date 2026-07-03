package com.altcraft.flutter.app

import android.annotation.SuppressLint
import com.altcraft.sdk.AltcraftSDK
import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

@SuppressLint("MissingFirebaseInstanceTokenRefresh")
class FCMService : FirebaseMessagingService() {
    override fun onMessageReceived(message: RemoteMessage) {
       AltcraftSDK.PushReceiver.takePush(this, message.data)
    }
}
