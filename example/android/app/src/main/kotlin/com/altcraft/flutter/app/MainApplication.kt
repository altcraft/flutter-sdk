package com.altcraft.flutter.app
import android.app.Application
import com.altcraft.sdk.AltcraftSDK

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        AltcraftSDK.setJWTProvider(JWTProvider(this))
        AltcraftSDK.pushTokenFunctions.setFCMTokenProvider(FCMProvider())
    }
}