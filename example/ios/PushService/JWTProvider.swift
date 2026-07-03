//
//  JWTProvider.swift
//  Example
//
//  Created by Andrey Pogodin.
//
//  Copyright © 2025 Altcraft. All rights reserved.

import Foundation
import Altcraft

class JWTProvider: JWTInterface {
    private let suiteName = "group.altcraft.flutter.app"
    private let key = "JWT_KEY"
    private let defaultJWT = "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjU5MjQ2ODY0MDUsImlzcyI6InNkayIsIm1hdGNoaW5nIjoie1wiZGJfaWRcIjoxLFwiZW1haWxcIjpcImFub255bW91c19kYkBsb2NhbGhvc3RcIixcIm1hdGNoaW5nXCI6XCJlbWFpbF9wcm9maWxlXCJ9IiwicnRva2VuIjoiMm5zVnJxWnBQaDNaLWI0ZGY3ZDEyZDc2NWM5NWUifQ.WxOsM9vXI5o8AtmGVzr1xLU0wiBKb367dgmA3cXr2OG458qWQeXaxa4hlqRQab981KrrjK_gU2KeHIUXcFI9Qw"
    

    func getToken() -> String? {
        return UserDefaults(suiteName: suiteName)?.string(forKey: key) ?? defaultJWT
    }
}
