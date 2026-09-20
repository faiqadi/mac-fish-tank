//
//  ParticleEffects.swift
//  desktop-habitat
//
//  Created by Faiqadi on 21/09/26.
//

import SpriteKit

/// Factory that builds particle emitters programmatically.
enum ParticleEffects {

    // MARK: - Ambient plankton / dust

    /// Tiny white specks that drift lazily through the water.
    static func ambientParticles(in size: CGSize) -> SKEmitterNode {
        let e = SKEmitterNode()
        e.particleBirthRate       = 3
        e.numParticlesToEmit      = 0        // infinite
        e.particleLifetime        = 12
        e.particleLifetimeRange   = 4

        e.particleSize            = CGSize(width: 2, height: 2)
        e.particleScaleRange      = 0.5

        e.particleColor           = .white
        e.particleAlpha           = 0.25
        e.particleAlphaRange      = 0.15
        e.particleAlphaSpeed      = -0.015

        e.particleSpeed           = 5
        e.particleSpeedRange      = 3
        e.emissionAngle           = .pi / 2        // upward
        e.emissionAngleRange      = .pi * 2        // spread all directions

        e.particlePositionRange   = CGVector(dx: size.width, dy: size.height)
        e.position                = CGPoint(x: size.width / 2, y: size.height / 2)
        e.zPosition               = 60

        e.particleBlendMode       = .add
        return e
    }

    // MARK: - Sparkle when fish eats food

    /// Brief sparkle burst at a specific position.
    static func eatSparkle(at position: CGPoint) -> SKEmitterNode {
        let e = SKEmitterNode()
        e.particleBirthRate       = 40
        e.numParticlesToEmit      = 12
        e.particleLifetime        = 0.5
        e.particleLifetimeRange   = 0.2

        e.particleSize            = CGSize(width: 3, height: 3)
        e.particleScaleRange      = 0.6
        e.particleScaleSpeed      = -1.5

        e.particleColor           = NSColor(red: 1.0, green: 0.85, blue: 0.4, alpha: 1)
        e.particleAlpha           = 0.9
        e.particleAlphaSpeed      = -1.5

        e.particleSpeed           = 40
        e.particleSpeedRange      = 20
        e.emissionAngle           = .pi / 2
        e.emissionAngleRange      = .pi * 2

        e.position                = position
        e.zPosition               = 90

        e.particleBlendMode       = .add

        // Auto-remove after particles expire
        let lifetime = 1.0
        e.run(.sequence([
            .wait(forDuration: lifetime),
            .removeFromParent()
        ]))

        return e
    }

    // MARK: - Whale Blowhole Spout Mist

    /// Fountain spray emitter for periodic whale blowhole spout.
    static func whaleSpout(at position: CGPoint) -> SKEmitterNode {
        let e = SKEmitterNode()
        e.particleBirthRate       = 120
        e.numParticlesToEmit      = 60
        e.particleLifetime        = 1.6
        e.particleLifetimeRange   = 0.5

        e.particleSize            = CGSize(width: 6, height: 6)
        e.particleScaleRange      = 0.7
        e.particleScaleSpeed      = 0.5

        e.particleColor           = NSColor(red: 0.85, green: 0.95, blue: 1.0, alpha: 0.85)
        e.particleAlpha           = 0.85
        e.particleAlphaSpeed      = -0.50

        e.particleSpeed           = 95
        e.particleSpeedRange      = 40
        e.emissionAngle           = .pi / 2        // upward vertical spout
        e.emissionAngleRange      = .pi * 0.32     // spray fan
        e.yAcceleration           = -50            // gravity arc

        e.position                = position
        e.zPosition               = 85
        e.particleBlendMode       = .add

        let lifetime = 2.4
        e.run(.sequence([
            .wait(forDuration: lifetime),
            .removeFromParent()
        ]))

        return e
    }
}

