package com.altcraft.flutter.app

import android.app.Application
import com.altcraft.sdk.AltcraftSDK
import com.altcraft.sdk.push.push

class MainApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        AltcraftSDK.auth.setJWTProvider(JWTProvider(this))
        AltcraftSDK.push.token.setFCMTokenProvider(FCMProvider())
    }
}
