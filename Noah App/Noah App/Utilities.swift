//
//  Utilities.swift
//  Noah App
//
//  Created by Danial Fajar on 21/07/2023.
//

import UIKit

final class Utilities {
    
    static let shared = Utilities()
    
    func isJailbroken() -> Bool {
        
        guard let cydiaUrlScheme = NSURL(string: "cydia://package/com.example.package") else { return false }
        if UIApplication.shared.canOpenURL(cydiaUrlScheme as URL) {
            return true
        }
        
        #if IOS_SIMULATOR
        
        return false
    
        #else
        
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: "/Applications/Cydia.app") ||
            fileManager.fileExists(atPath: "/Library/MobileSubstrate/MobileSubstrate.dylib") ||
            fileManager.fileExists(atPath: "/bin/bash") ||
            fileManager.fileExists(atPath: "/usr/sbin/sshd") ||
            fileManager.fileExists(atPath: "/etc/apt") ||
            fileManager.fileExists(atPath: "/usr/bin/ssh") ||
            fileManager.fileExists(atPath: "/private/var/lib/apt") {
            return true
        }
        
        if isJailbrokenCanOpen(path: "/Applications/Cydia.app") ||
            isJailbrokenCanOpen(path: "/Library/MobileSubstrate/MobileSubstrate.dylib") ||
            isJailbrokenCanOpen(path: "/bin/bash") ||
            isJailbrokenCanOpen(path: "/usr/sbin/sshd") ||
            isJailbrokenCanOpen(path: "/etc/apt") ||
            isJailbrokenCanOpen(path: "/usr/bin/ssh") {
            return true
        }
        
        let path = "/private/" + NSUUID().uuidString
        do {
            try "anyString".write(toFile: path, atomically: true, encoding: String.Encoding.utf8)
            try fileManager.removeItem(atPath: path)
            return true
        } catch {
            return false
        }
        
        #endif
    }

    func isJailbrokenCanOpen(path: String) -> Bool {
        let file = fopen(path, "r")
        guard file != nil else { return false }
        fclose(file)
        return true
    }
}
