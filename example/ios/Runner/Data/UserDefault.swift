//
//  UserDefault.swift
//  Runner
//
//  Created by Andrey Pogodin.
//
//  Copyright © 2026 Altcraft. All rights reserved.


func setAPNsTokenInUserDefault(_ deviceToken: Data) {
    UserDefaults.standard.set(deviceToken, forKey: "apnsTokenData")

    let tokenString = deviceToken.map {
        String(format: "%02x", $0)
    }.joined()

    UserDefaults.standard.set(tokenString, forKey: "apnsTokenString")
}

func getAPNsTokenDataFromUserDefaults() -> Data? {
    UserDefaults.standard.data(forKey: "apnsTokenData")
}

func getAPNsTokenFromUserDefault() -> String? {
    UserDefaults.standard.string(forKey: "apnsTokenString")
}
