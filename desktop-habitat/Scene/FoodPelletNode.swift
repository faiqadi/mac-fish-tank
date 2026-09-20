//
//  FoodPelletNode.swift
//  desktop-habitat
//
//  Created by Faiqadi on 21/09/26.
//

import SpriteKit

/// A food pellet that sinks through the water and can be eaten by fish.
class FoodPelletNode: SKNode {

    // MARK: - Properties

    let pelletRadius: CGFloat = 3.0
    var isEaten: Bool = false

    private let shape: SKShapeNode
    private var sinkSpeed: CGFloat
    private var lateralDrift: CGFloat
    private var age: TimeInterval = 0
    private let maxAge: TimeInterval

    // MARK: - Init

    init(at position: CGPoint) {
        sinkSpeed    = CGFloat.random(in: 18...35)
        lateralDrift = CGFloat.random(in: -12...12)
        maxAge       = TimeInterval.random(in: 20...40)

        shape = SKShapeNode(circleOfRadius: pelletRadius)
        shape.fillColor   = NSColor(red: 0.72, green: 0.42, blue: 0.14, alpha: 1)
        shape.strokeColor = NSColor(red: 0.52, green: 0.30, blue: 0.10, alpha: 0.7)
        shape.lineWidth   = 0.5

        super.init()
        self.position  = position
        self.zPosition = 50
        addChild(shape)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError() }

    // MARK: - Per-frame update

    func update(deltaTime dt: TimeInterval, sandY: CGFloat) {
        guard !isEaten else { return }
        age += dt

        // Sink until resting on the sand
        if position.y > sandY + pelletRadius {
            position.y -= sinkSpeed * CGFloat(dt)
            position.x += lateralDrift * CGFloat(dt)
            lateralDrift *= 0.997   // dampen drift
        }

        // Dissolve in the last 30 % of lifetime
        let dissolveStart = maxAge * 0.7
        if age > dissolveStart {
            let frac = (age - dissolveStart) / (maxAge * 0.3)
            shape.alpha = CGFloat(max(0, 1.0 - frac))
        }

        if age > maxAge {
            removeFromParent()
        }
    }

    // MARK: - Eaten animation

    func eat() {
        isEaten = true
        run(.sequence([
            .group([.scale(to: 0, duration: 0.15),
                    .fadeOut(withDuration: 0.15)]),
            .removeFromParent()
        ]))
    }
}
