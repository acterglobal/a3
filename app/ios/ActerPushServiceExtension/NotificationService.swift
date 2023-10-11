//
//  NotificationService.swift
//  ActerPushServiceExtension
//
//  Created by Benjamin Kampmann on 29/09/2023.
//
import UserNotifications
import os.log

@available(iOS 10.0, *)
class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest,
                            withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        Logger.push.log("Push received!")
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        guard let roomId = request.roomId,
            let eventId = request.eventId,
            let deviceId = request.deviceId else {
                Logger.push.log("not a matrix push ...");
                // FIXME: forward to awesome_notifications_fcm?!?
                return contentHandler(request.content)
            }

        Logger.push.log("read from store following... for \(deviceId, privacy: .public)");
        let sessionKey = read_from_store(key: deviceId, groupId: "V45JGKTC6K.global.acter.a3", accountName: nil, synchronizable: true);
        Logger.push.log("Session found: \(sessionKey ?? "(none)", privacy: .public)");

        
        if let bestAttemptContent = bestAttemptContent {
            // Modify the notification content here...
            bestAttemptContent.body = "New message received"
            
            contentHandler(bestAttemptContent)
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }

    private func baseQuery(key: String?, groupId: String?, accountName: String?, synchronizable: Bool?, returnData: Bool?) -> Dictionary<CFString, Any> {
        var keychainQuery: [CFString: Any] = [kSecClass : kSecClassGenericPassword]
        if (key != nil) {
            keychainQuery[kSecAttrAccount] = key
            
        }
        
        if (groupId != nil) {
            keychainQuery[kSecAttrAccessGroup] = groupId
        }
        
        if (accountName != nil) {
            keychainQuery[kSecAttrService] = accountName
        }
        
        if (synchronizable != nil) {
            keychainQuery[kSecAttrSynchronizable] = synchronizable
        }
        
        if (returnData != nil) {
            keychainQuery[kSecReturnData] = returnData
        }
        return keychainQuery
    }

    internal func read_from_store(key: String, groupId: String?, accountName: String?, synchronizable: Bool?) -> String? {
        var keychainQuery = baseQuery(key: key, groupId: groupId, accountName: accountName, synchronizable: synchronizable, returnData: true)
        
        var ref: AnyObject?
        let status = SecItemCopyMatching(
            keychainQuery as CFDictionary,
            &ref
        )
        
        if (status == noErr) {
            var value: String? = nil
            return String(data: ref as! Data, encoding: .utf8)
        }

        Logger.push.log("Failed to read from store: \(status)")
        return nil
    }

}
