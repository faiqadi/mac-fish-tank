//
//  CausticsEffect.swift
//  desktop-habitat
//
//  Created by Faiqadi on 21/09/26.
//

import SpriteKit

/// Animated light-caustic patterns on the sand floor.
class CausticsEffect: SKNode {

    private struct Blob {
        let node: SKShapeNode
        let baseX: CGFloat
        let baseY: CGFloat
        let driftSpeed: CGFloat
        let pulseSpeed: CGFloat
        let phase: CGFloat
    }

    private var blobs: [Blob] = []

    // MARK: - Init

    init(floorWidth: CGFloat, floorHeight: CGFloat, count: Int = 18) {
        super.init()
        self.zPosition = 2

        for _ in 0..<count {
            let w: CGFloat = .random(in: 30...80)
            let h: CGFloat = .random(in: 20...50)
            let x: CGFloat = .random(in: 0...floorWidth)
            let y: CGFloat = .random(in: 0...floorHeight)

            let ellipse = SKShapeNode(ellipseOf: CGSize(width: w, height: h))
            ellipse.fillColor   = NSColor(white: 1.0, alpha: .random(in: 0.03...0.07))
            ellipse.strokeColor = .clear
            ellipse.position    = CGPoint(x: x, y: y)
            ellipse.blendMode   = .add
            addChild(ellipse)

            blobs.append(Blob(
                node: ellipse,
                baseX: x, baseY: y,
                driftSpeed: .random(in: 0.3...1.0),
                pulseSpeed: .random(in: 0.4...1.2),
                phase: .random(in: 0 ... .pi * 2)
            ))
        }
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError() }

    // MARK: - Update

    func update(time t: TimeInterval) {
        let ct = CGFloat(t)
        for b in blobs {
            // Slow drift
            b.node.position.x = b.baseX + sin(ct * b.driftSpeed + b.phase) * 25
            b.node.position.y = b.baseY + cos(ct * b.driftSpeed * 0.7 + b.phase) * 12

            // Gentle pulse
            let scale = 1.0 + sin(ct * b.pulseSpeed + b.phase) * 0.15
            b.node.setScale(scale)
        }
    }
}
