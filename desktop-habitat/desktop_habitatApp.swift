//
//  desktop_habitatApp.swift
//  desktop-habitat
//
//  Created by Faiqadi on 21/09/26.
//

import SwiftUI

@main
struct desktop_habitatApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No visible window — the aquarium lives in the overlay panel.
        Settings { EmptyView() }
    }
}
