//
//  ActerLogger.swift
//  ActerPushServiceExtension
//
//  Created by Benjamin Kampmann on 03/10/2023.
//
import OSLog

extension Logger {
    /// Using your bundle identifier is a great way to ensure a unique identifier.
    private static var subsystem = Bundle.main.bundleIdentifier!

    /// Logs the view cycles like a view that appeared.
    static let push = Logger(subsystem: subsystem, category: "process")
}
