//
//  AppDelegate.swift
//  desktop-habitat
//
//  Created by Faiqadi on 21/09/26.
//

import Cocoa
import SpriteKit

/// Creates a transparent, borderless overlay panel that hosts the aquarium.
class AppDelegate: NSObject, NSApplicationDelegate {

    // MARK: - Properties

    private var overlayPanel: NSPanel!
    private var skView: SKView!
    private var aquariumScene: AquariumScene!
    private var menuBarController: MenuBarController!
    private let config = AquariumConfig()
    private var cursorMonitor: Any?

    // MARK: - Lifecycle

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Hide from Dock — menu-bar-only app
        NSApp.setActivationPolicy(.accessory)

        guard let screen = NSScreen.main else { return }
        let frame = screen.frame

        // ---- Overlay panel ----
        overlayPanel = NSPanel(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        // Just above the desktop wallpaper, below everything else
        overlayPanel.level = NSWindow.Level(
            rawValue: Int(CGWindowLevelForKey(.desktopWindow)) + 1
        )
        overlayPanel.isOpaque          = false
        overlayPanel.backgroundColor   = .clear
        overlayPanel.hasShadow         = false
        overlayPanel.ignoresMouseEvents = config.isClickThrough
        overlayPanel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        overlayPanel.hidesOnDeactivate  = false

        // ---- SpriteKit view ----
        skView = SKView(frame: CGRect(origin: .zero, size: frame.size))
        skView.allowsTransparency = true
        skView.autoresizingMask   = [.width, .height]
        overlayPanel.contentView  = skView

        // ---- Aquarium scene ----
        aquariumScene              = AquariumScene(size: frame.size)
        aquariumScene.scaleMode    = .resizeFill
        aquariumScene.backgroundColor = .clear
        aquariumScene.config       = config
        skView.presentScene(aquariumScene)

        // Restore pause state
        if config.isPaused { aquariumScene.isPaused = true }

        overlayPanel.orderFront(nil)

        // ---- Menu bar ----
        menuBarController = MenuBarController(
            scene: aquariumScene, config: config, panel: overlayPanel
        )

        // ---- Global cursor tracking ----
        cursorMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged]
        ) { [weak self] _ in
            self?.aquariumScene.updateCursorPosition(NSEvent.mouseLocation)
        }

        // ---- Screen-change observer ----
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let monitor = cursorMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }

    // MARK: - Screen changes

    @objc private func screenDidChange(_ note: Notification) {
        guard let screen = NSScreen.main else { return }
        overlayPanel.setFrame(screen.frame, display: true)
        aquariumScene.size = screen.frame.size
    }
}
