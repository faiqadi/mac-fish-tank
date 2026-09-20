//
//  BubbleNode.swift
//  desktop-habitat
//
//  Created by Faiqadi on 21/09/26.
//

import SpriteKit

/// A single bubble that rises from the bottom, wobbles, and fades at the surface.
class BubbleNode: SKNode {

    // MARK: - Properties

    private let bubble: SKShapeNode
    private let radius: CGFloat
    private let riseSpeed: CGFloat
    private let wobbleAmp: CGFloat
    private let wobbleFreq: CGFloat
    private let startX: CGFloat
    private var age: TimeInterval = 0

    // MARK: - Init

    init(at position: CGPoint, size: CGFloat? = nil) {
        radius      = size ?? CGFloat.random(in: 2...6)
        riseSpeed   = CGFloat.random(in: 40...80)
        wobbleAmp   = CGFloat.random(in: 5...15)
        wobbleFreq  = CGFloat.random(in: 1...3)
        startX      = position.x

        // Main bubble circle
        bubble = SKShapeNode(circleOfRadius: radius)
        bubble.fillColor   = NSColor(white: 1.0, alpha: 0.25)
        bubble.strokeColor = NSColor(white: 1.0, alpha: 0.45)
        bubble.lineWidth   = 0.5
        bubble.glowWidth   = 0.5

        // Small specular highlight
        let hl = SKShapeNode(circleOfRadius: radius * 0.3)
        hl.fillColor   = NSColor(white: 1.0, alpha: 0.55)
        hl.strokeColor = .clear
        hl.position    = CGPoint(x: -radius * 0.25, y: radius * 0.25)
        bubble.addChild(hl)

        super.init()
        self.position = position
        self.zPosition = 80
        addChild(bubble)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError() }

    // MARK: - Per-frame update

    func update(deltaTime dt: TimeInterval, waterSurfaceY surfaceY: CGFloat) {
        age += dt

        // Rise
        position.y += riseSpeed * CGFloat(dt)

        // Horizontal wobble
        position.x = startX + wobbleAmp * sin(CGFloat(age) * wobbleFreq * .pi * 2)

        // Grow slightly as pressure decreases
        let depthFraction = min(position.y / surfaceY, 1.0)
        bubble.setScale(1.0 + depthFraction * 0.3)

        // Fade near the surface
        let surfaceDist = surfaceY - position.y
        if surfaceDist < 80 {
            bubble.alpha = max(0, surfaceDist / 80)
        }

        // Remove once past the surface
        if position.y > surfaceY + 20 {
            removeFromParent()
        }
    }
}
