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

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler
        Logger.push.log("Push received!")
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
        if let sessions = UserDefaults.standard.string(forKey: "flutter.sessions") {
            print(sessions)
            Logger.push.log("sessions: %{sessions}")
        } else {
            print("no sessions found.")
            Logger.push.log("no sessions found!")
            return
        }

        
        if let bestAttemptContent = bestAttemptContent {
            // Modify the notification content here...
            bestAttemptContent.title = "modified !"
            
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

}
