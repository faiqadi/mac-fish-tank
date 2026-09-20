//
//  MenuBarController.swift
//  desktop-habitat
//
//  Created by Faiqadi on 21/09/26.
//

import Cocoa
import SpriteKit

/// Manages the 🐠 menu-bar status item.
class MenuBarController {

    private let statusItem: NSStatusItem
    private let scene: AquariumScene
    private let config: AquariumConfig
    private let panel: NSPanel

    init(scene: AquariumScene, config: AquariumConfig, panel: NSPanel) {
        self.scene  = scene
        self.config = config
        self.panel  = panel

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "🐠"

        let menu = NSMenu()

        let feedItem = NSMenuItem(title: "Feed", action: #selector(feed), keyEquivalent: "f")
        feedItem.target = self
        menu.addItem(feedItem)

        let pauseItem = NSMenuItem(
            title: config.isPaused ? "Resume" : "Pause",
            action: #selector(togglePause),
            keyEquivalent: "p"
        )
        pauseItem.target = self
        menu.addItem(pauseItem)

        menu.addItem(.separator())

        let clickItem = NSMenuItem(
            title: "Toggle Click-Through",
            action: #selector(toggleClickThrough),
            keyEquivalent: "t"
        )
        clickItem.target = self
        menu.addItem(clickItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }

    // MARK: - Actions

    @objc private func feed() {
        scene.dropFood()
    }

    @objc private func togglePause() {
        config.isPaused.toggle()
        scene.isPaused = config.isPaused

        if let item = statusItem.menu?.items.first(where: { $0.action == #selector(togglePause) }) {
            item.title = config.isPaused ? "Resume" : "Pause"
        }
    }

    @objc private func toggleClickThrough() {
        config.isClickThrough.toggle()
        panel.ignoresMouseEvents = config.isClickThrough
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
