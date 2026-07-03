package com.altcraft.flutter.app

import android.app.Application
import com.altcraft.sdk.interfaces.JWTInterface

class JWTProvider(private val context: Application) : JWTInterface {
    private val prefs by lazy {
        context.getSharedPreferences("altcraft_sdk", Application.MODE_PRIVATE)
    }

    private val defaultJWT = ""

    override fun getJWT(): String? {
        return prefs.getString("JWT_KEY", null) ?: defaultJWT
    }
}
