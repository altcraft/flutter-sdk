package com.altcraft.flutter.app

import com.altcraft.sdk.push.platform.token.provider.FCMInterface
import com.google.firebase.Firebase
import com.google.firebase.messaging.FirebaseMessaging
import com.google.firebase.messaging.messaging
import kotlinx.coroutines.tasks.await

class FCMProvider : FCMInterface {
    override suspend fun getToken(): String? {
        return try {
            Firebase.messaging.token.await()
        } catch (_: Exception) {
            null
        }
    }

    override fun deleteToken(completion: (Boolean) -> Unit) {
        try {
            FirebaseMessaging.getInstance().deleteToken().addOnCompleteListener {
                completion(it.isSuccessful)
            }
        } catch (_: Exception) {
            completion(false)
        }
    }
}