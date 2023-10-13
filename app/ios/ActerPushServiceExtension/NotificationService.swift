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
                Logger.push.error("not a matrix push ... \(request.content)");
                return discard()
            }

        Logger.push.log("read from store following... for \(deviceId, privacy: .public)");
        guard let sessionKey = read_from_store(key: deviceId, groupId: "V45JGKTC6K.global.acter.a3", accountName: nil, synchronizable: true) else {
            Logger.push.error("active session \(deviceId, privacy: .public) not found for push. ignoring");
            return discard()
        }

        Task {
            await handle(session: sessionKey,
                          roomId: roomId,
                          eventId: eventId,
                          unreadCount: request.unreadCount)
        }
    }


    private func handle(session: String,
                        roomId: String,
                        eventId: String,
                        unreadCount: Int?) async {

        do {
            Logger.push.log("Session found: \(session, privacy: .public)");
            let notification = try await getNotificationItem(session, roomId, eventId);
            
            
            if let bestAttemptContent = bestAttemptContent {
                bestAttemptContent.title = notification.roomDisplayName
                if (notification.isInvite) {
                    bestAttemptContent.body = "invited by \(notification.senderDisplayName)"
                } else if (notification.unsupported) {
                    bestAttemptContent.body = "??? by \(notification.senderDisplayName)"
                } else {
                    if (notification.isDirectMessageRoom) {
                        bestAttemptContent.body = notification.shortMsg;
                    } else {
                        bestAttemptContent.body = "\(notification.senderDisplayName) : \(notification.shortMsg)"
                    }
                }
                notify()
            } else {
                discard()
            }
        } catch {
            Logger.push.error("NSE run error: \(error)")
            return discard()
        }
    }

    private func notify() {
        guard let bestAttemptContent else {
            Logger.push.info("notify: no modified content")
            return discard()
        }

        contentHandler?(bestAttemptContent)
        cleanUp()
    }

    private func discard() {
        contentHandler?(UNMutableNotificationContent())
        cleanUp()
    }

    private func cleanUp() {
        contentHandler = nil
        bestAttemptContent = nil
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        notify()
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
            return String(data: ref as! Data, encoding: .utf8)
        }

        Logger.push.log("Failed to read from store: \(status)")
        return nil
    }

}
