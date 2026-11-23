//  NotificationService.swift
//  PushService
//
//  Created by Andrey Pogodin.
//
//  Copyright © 2025 Altcraft. All rights reserved.

import AltcraftCore
import AltcraftPush
import Foundation
import UserNotifications

class NotificationService: UNNotificationServiceExtension {
    
    /// - important! Set app groups identifier.
    let appGroupID = "group.altcraft.flutter.app"
    
    /// - important! Set the provider to JWT if you are using JWT authentication.
    let jwtProvider = JWTProvider()

    /// Processes the incoming push: downloads rich media, applies action
    /// buttons and delivers the modified content.
    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (
            UNNotificationContent
        ) -> Void
    ) {
        AltcraftNSE.setAppGroup(groupName: appGroupID)
        AltcraftNSE.setJWTProvider(provider: jwtProvider)
        
        if AltcraftNSE.isAltcraftPush(request) {
            AltcraftNSE.handleNotificationRequest(
                request: request,
                contentHandler: contentHandler
            )
        } else {
            contentHandler(request.content)
        }
    }
    /// Delivers the best-available content when the extension runtime
    /// is about to expire.
    override func serviceExtensionTimeWillExpire() {
        AltcraftNSE.serviceExtensionTimeWillExpire()
    }
}
