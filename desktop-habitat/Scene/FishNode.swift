//
//  FishNode.swift
//  desktop-habitat
//
//  Created by Faiqadi on 21/09/26.
//

import SpriteKit

// MARK: - Fish Species Catalog

enum FishSpecies: CaseIterable {
    case clownfish, angelfish, neonTetra, guppy, goldfish, betta

    var lengthRange: ClosedRange<CGFloat> {
        switch self {
        case .clownfish:  return 38...48
        case .angelfish:  return 34...44
        case .neonTetra:  return 20...28
        case .guppy:      return 18...26
        case .goldfish:   return 40...54
        case .betta:      return 36...46
        }
    }

    var bodyAspect: CGFloat {
        switch self {
        case .angelfish:  return 0.72
        case .goldfish:   return 0.58
        case .betta:      return 0.44
        default:          return 0.40
        }
    }

    /// Primary colors for body gradient rendering
    var primaryColor: NSColor {
        switch self {
        case .clownfish:  return NSColor(red: 0.98, green: 0.48, blue: 0.08, alpha: 1)
        case .angelfish:  return NSColor(red: 0.84, green: 0.87, blue: 0.90, alpha: 1)
        case .neonTetra:  return NSColor(red: 0.20, green: 0.45, blue: 0.75, alpha: 1)
        case .guppy:      return NSColor(red: 0.42, green: 0.62, blue: 0.45, alpha: 1)
        case .goldfish:   return NSColor(red: 0.98, green: 0.58, blue: 0.12, alpha: 1)
        case .betta:      return NSColor(red: 0.55, green: 0.12, blue: 0.75, alpha: 1)
        }
    }

    var dorsalColor: NSColor {
        switch self {
        case .clownfish:  return NSColor(red: 0.85, green: 0.28, blue: 0.02, alpha: 1)
        case .angelfish:  return NSColor(red: 0.52, green: 0.56, blue: 0.60, alpha: 1)
        case .neonTetra:  return NSColor(red: 0.08, green: 0.20, blue: 0.55, alpha: 1)
        case .guppy:      return NSColor(red: 0.25, green: 0.38, blue: 0.28, alpha: 1)
        case .goldfish:   return NSColor(red: 0.85, green: 0.40, blue: 0.04, alpha: 1)
        case .betta:      return NSColor(red: 0.32, green: 0.05, blue: 0.55, alpha: 1)
        }
    }

    var bellyColor: NSColor {
        switch self {
        case .clownfish:  return NSColor(red: 1.00, green: 0.75, blue: 0.38, alpha: 1)
        case .angelfish:  return NSColor(red: 0.95, green: 0.96, blue: 0.96, alpha: 1)
        case .neonTetra:  return NSColor(red: 0.85, green: 0.88, blue: 0.90, alpha: 1)
        case .guppy:      return NSColor(red: 0.82, green: 0.86, blue: 0.76, alpha: 1)
        case .goldfish:   return NSColor(red: 1.00, green: 0.88, blue: 0.58, alpha: 1)
        case .betta:      return NSColor(red: 0.75, green: 0.35, blue: 0.92, alpha: 1)
        }
    }

    var finColor: NSColor {
        switch self {
        case .clownfish:  return NSColor(red: 0.95, green: 0.45, blue: 0.05, alpha: 0.75)
        case .angelfish:  return NSColor(red: 0.72, green: 0.76, blue: 0.80, alpha: 0.65)
        case .neonTetra:  return NSColor(red: 0.65, green: 0.75, blue: 0.85, alpha: 0.60)
        case .guppy:      return NSColor(red: 0.95, green: 0.55, blue: 0.15, alpha: 0.75)
        case .goldfish:   return NSColor(red: 1.00, green: 0.70, blue: 0.20, alpha: 0.70)
        case .betta:      return NSColor(red: 0.82, green: 0.20, blue: 0.48, alpha: 0.80)
        }
    }

    var irisColor: NSColor {
        switch self {
        case .clownfish:  return NSColor(red: 0.92, green: 0.72, blue: 0.15, alpha: 1)
        case .angelfish:  return NSColor(red: 0.85, green: 0.52, blue: 0.10, alpha: 1)
        case .neonTetra:  return NSColor(red: 0.18, green: 0.70, blue: 0.95, alpha: 1)
        case .guppy:      return NSColor(red: 0.22, green: 0.22, blue: 0.22, alpha: 1)
        case .goldfish:   return NSColor(red: 0.18, green: 0.18, blue: 0.18, alpha: 1)
        case .betta:      return NSColor(red: 0.85, green: 0.22, blue: 0.22, alpha: 1)
        }
    }

    var cruiseSpeed: CGFloat {
        switch self {
        case .neonTetra, .guppy:    return 50
        case .clownfish, .goldfish: return 38
        case .angelfish:            return 30
        case .betta:                return 34
        }
    }

    var maxSpeed: CGFloat { cruiseSpeed * 2.8 }
}

// MARK: - Behavior State Machine

enum FishBehaviorMode {
    case hover
    case travel(goal: CGPoint, recruited: Bool)
    case inspect(point: CGPoint)
    case settle
    case feed(pellet: FoodPelletNode)
    case escape(from: CGPoint)

    var isEscape: Bool {
        if case .escape = self { return true }
        return false
    }
    var isFeed: Bool {
        if case .feed = self { return true }
        return false
    }
    var isHover: Bool {
        if case .hover = self { return true }
        return false
    }
}

// MARK: - Flick / C-Start Data

private struct FishFlick {
    let start: TimeInterval
    let yaw0: CGFloat
    let angle: CGFloat
    let curvature: CGFloat
    let thrust: CGFloat
    let stage1: TimeInterval
    let stage2: TimeInterval
    let burst: TimeInterval
    let burstThrust: CGFloat
}

// MARK: - Propulsive Tail Stroke

private struct FishStroke {
    let start: TimeInterval
    let end: TimeInterval
    let thrust: CGFloat
}

// MARK: - Spine Vertebra Definition

private struct SpineJoint {
    var position: CGPoint
    var angle: CGFloat
    var halfHeight: CGFloat
}

// MARK: - FishNode

class FishNode: SKNode {

    // Identity & Morphology
    let species: FishSpecies
    let bodyLength: CGFloat
    let bodyHeight: CGFloat
    let character: CGFloat

    // AI & Kinematic State
    private(set) var mode: FishBehaviorMode = .hover
    private var modeTimer: TimeInterval = 0
    private var heading: CGPoint = CGPoint(x: 1, y: 0)
    private var targetHeading: CGPoint = CGPoint(x: 1, y: 0)
    private var currentPitch: CGFloat = 0
    private var swimVelocity: CGPoint = .zero
    private var anchorPoint: CGPoint = .zero
    private var curiosity: CGFloat = .random(in: 0...0.6)
    private var alarm: CGFloat = 0
    private var refractoryUntil: TimeInterval = 0
    private var lastFlickTime: TimeInterval = -10
    private var currentFlick: FishFlick?
    private var currentStroke: FishStroke?
    private var nextStrokeTime: TimeInterval = 0
    private var nextTwitchTime: TimeInterval = 0
    private var nextExcursionTime: TimeInterval = 0

    // Multi-Sensory Feeding Clocks
    private(set) var keenAppetite: CGFloat = 0
    private(set) var searchingAppetite: CGFloat = 0
    private var appetite: CGFloat = 1.0
    private var strikeUntil: TimeInterval = 0
    private var handlingUntil: TimeInterval = 0
    private var strikeAttempts: Int = 0
    private var nextScanTime: TimeInterval = 0
    private var targetPellet: FoodPelletNode?
    private var splashReactionTime: TimeInterval = 0
    private var splashTargetPoint: CGPoint = .zero

    // Fluid Spline Kinematics & Wave Deformation
    private var swimPhase: CGFloat = .random(in: 0 ... .pi * 2)
    private var finPhase: CGFloat = .random(in: 0 ... .pi * 2)
    private var breathPhase: CGFloat = .random(in: 0 ... .pi * 2)
    private var bodyEffort: CGFloat = 0
    private var bodyBend: CGFloat = 0
    private var pectoralBrake: CGFloat = 0.2

    // Dynamic Render Nodes
    private var bodyShapeNode: SKShapeNode!
    private var bodyShineNode: SKShapeNode!
    private var speciesPatternNode: SKShapeNode!
    private var caudalFinNode: SKShapeNode!
    private var caudalRaysNode: SKShapeNode!
    private var dorsalFinNode: SKShapeNode!
    private var leftPectoralFin: SKShapeNode!
    private var rightPectoralFin: SKShapeNode!
    private var pelvicFinNode: SKShapeNode!
    private var eyeContainer: SKNode!
    private var gillLineNode: SKShapeNode!

    // Spine Vertebrae (10 joints from snout to caudal base)
    private let spineJointCount = 10
    private var spineJoints: [SpineJoint] = []

    // MARK: - Init

    init(species: FishSpecies) {
        self.species    = species
        self.bodyLength = .random(in: species.lengthRange)
        self.bodyHeight = bodyLength * species.bodyAspect
        self.character  = .random(in: 0.85...1.15)
        super.init()

        initializeSpine()
        buildVisualHierarchy()
        self.zPosition = .random(in: 20...60)
        let initialYaw = CGFloat.random(in: -0.15...0.15) + (Bool.random() ? 0 : .pi)
        self.heading   = CGPoint(x: cos(initialYaw), y: sin(initialYaw))
        self.targetHeading = self.heading
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError() }

    // ─────────────────────────────────────────────
    // MARK: - Spine Initialization
    // ─────────────────────────────────────────────

    private func initializeSpine() {
        spineJoints = (0..<spineJointCount).map { i in
            let s = CGFloat(i) / CGFloat(spineJointCount - 1)
            let x = bodyLength * (0.45 - s)
            let h = calculateBodyHalfHeight(at: s)
            return SpineJoint(position: CGPoint(x: x, y: 0), angle: 0, halfHeight: h)
        }
    }

    private func calculateBodyHalfHeight(at s: CGFloat) -> CGFloat {
        let h = bodyHeight * 0.5
        if s < 0.15 {
            // Snout to eye taper
            return h * (0.20 + (s / 0.15) * 0.65)
        } else if s < 0.38 {
            // Eye to max thorax
            let t = (s - 0.15) / 0.23
            return h * (0.85 + sin(t * .pi * 0.5) * 0.15)
        } else if s < 0.72 {
            // Thorax to abdomen
            let t = (s - 0.38) / 0.34
            return h * (1.0 - t * 0.45)
        } else {
            // Caudal peduncle taper
            let t = (s - 0.72) / 0.28
            return h * (0.55 - t * 0.38)
        }
    }

    // ─────────────────────────────────────────────
    // MARK: - Visual Hierarchy Construction
    // ─────────────────────────────────────────────

    private func buildVisualHierarchy() {
        // 1. Right (Background) Pectoral Fin
        rightPectoralFin = makePectoralFin(isRightSide: true)
        rightPectoralFin.zPosition = -2
        addChild(rightPectoralFin)

        // 3. Dorsal Fin (Translucent with fin rays)
        dorsalFinNode = SKShapeNode()
        dorsalFinNode.fillColor   = species.finColor
        dorsalFinNode.strokeColor = species.finColor.withAlphaComponent(0.4)
        dorsalFinNode.lineWidth   = 0.5
        dorsalFinNode.zPosition   = -1
        addChild(dorsalFinNode)

        // 4. Pelvic / Ventral Fin
        pelvicFinNode = SKShapeNode()
        pelvicFinNode.fillColor   = species.finColor.withAlphaComponent(0.65)
        pelvicFinNode.strokeColor = .clear
        pelvicFinNode.zPosition   = -1
        addChild(pelvicFinNode)

        // 5. Caudal Fin (Tail) & Fin Rays
        caudalFinNode = SKShapeNode()
        caudalFinNode.fillColor   = species.finColor
        caudalFinNode.strokeColor = species.finColor.withAlphaComponent(0.5)
        caudalFinNode.lineWidth   = 0.6
        caudalFinNode.zPosition   = -1
        addChild(caudalFinNode)

        caudalRaysNode = SKShapeNode()
        caudalRaysNode.strokeColor = NSColor(white: 1.0, alpha: 0.3)
        caudalRaysNode.lineWidth   = 0.5
        caudalRaysNode.zPosition   = -0.5
        addChild(caudalRaysNode)

        // 6. Main Seamless Spline Body
        bodyShapeNode = SKShapeNode()
        bodyShapeNode.fillColor   = species.primaryColor
        bodyShapeNode.strokeColor = species.dorsalColor.withAlphaComponent(0.5)
        bodyShapeNode.lineWidth   = 0.8
        bodyShapeNode.zPosition   = 0
        addChild(bodyShapeNode)

        // 7. Specular Flank Highlight
        bodyShineNode = SKShapeNode()
        bodyShineNode.fillColor   = NSColor(white: 1.0, alpha: 0.22)
        bodyShineNode.strokeColor = .clear
        bodyShineNode.zPosition   = 0.5
        addChild(bodyShineNode)

        // 8. Species Patterns (Stripes, bands, spots)
        speciesPatternNode = SKShapeNode()
        speciesPatternNode.zPosition = 1.0
        addChild(speciesPatternNode)

        // 9. Curved Gill Operculum Line
        gillLineNode = SKShapeNode()
        gillLineNode.strokeColor = NSColor(white: 0, alpha: 0.28)
        gillLineNode.lineWidth   = 0.8
        gillLineNode.zPosition   = 1.2
        addChild(gillLineNode)

        // 10. Multi-Layer Realistic Eye
        eyeContainer = buildEyeNode()
        eyeContainer.zPosition = 2.0
        addChild(eyeContainer)

        // 11. Left (Foreground) Pectoral Fin
        leftPectoralFin = makePectoralFin(isRightSide: false)
        leftPectoralFin.zPosition = 3.0
        addChild(leftPectoralFin)
    }

    private func makePectoralFin(isRightSide: Bool) -> SKShapeNode {
        let fw = bodyLength * 0.26
        let fh = bodyHeight * 0.35
        let path = CGMutablePath()
        path.move(to: .zero)
        let dir: CGFloat = isRightSide ? 1 : -1
        path.addCurve(to: CGPoint(x: -fw, y: dir * fh * 0.55),
                      control1: CGPoint(x: -fw * 0.2, y: dir * fh * 0.25),
                      control2: CGPoint(x: -fw * 0.8, y: dir * fh * 0.70))
        path.addQuadCurve(to: .zero, control: CGPoint(x: -fw * 0.35, y: dir * fh * 0.10))
        path.closeSubpath()

        let fin = SKShapeNode(path: path)
        fin.fillColor   = species.finColor.withAlphaComponent(0.65)
        fin.strokeColor = species.finColor.withAlphaComponent(0.35)
        fin.lineWidth   = 0.5
        return fin
    }

    private func buildEyeNode() -> SKNode {
        let eyeR = bodyHeight * 0.16
        let root = SKNode()

        // Sclera
        let sclera = SKShapeNode(circleOfRadius: eyeR)
        sclera.fillColor   = NSColor(white: 0.96, alpha: 1)
        sclera.strokeColor = NSColor(white: 0.15, alpha: 0.8)
        sclera.lineWidth   = 0.5
        root.addChild(sclera)

        // Iris
        let iris = SKShapeNode(circleOfRadius: eyeR * 0.75)
        iris.fillColor   = species.irisColor
        iris.strokeColor = .clear
        root.addChild(iris)

        // Pupil
        let pupil = SKShapeNode(circleOfRadius: eyeR * 0.45)
        pupil.fillColor   = NSColor(white: 0.04, alpha: 1)
        pupil.strokeColor = .clear
        root.addChild(pupil)

        // Specular Glint
        let glint = SKShapeNode(circleOfRadius: eyeR * 0.22)
        glint.fillColor   = .white
        glint.strokeColor = .clear
        glint.position    = CGPoint(x: eyeR * 0.22, y: eyeR * 0.22)
        root.addChild(glint)

        return root
    }

    // ─────────────────────────────────────────────
    // MARK: - Sensory Events & Stimuli
    // ─────────────────────────────────────────────

    func recordSplash(at point: CGPoint, time: TimeInterval) {
        let dist = hypot(point.x - position.x, point.y - position.y)
        guard dist < 500, !mode.isEscape else { return }
        splashReactionTime = time + Double(dist / 500.0) * 0.22 + .random(in: 0.04...0.12)
        splashTargetPoint  = point
        rouseAppetite(0.4)
    }

    func triggerContagionAlarm(from dangerSource: CGPoint, latency: TimeInterval) {
        guard !mode.isEscape else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + latency) { [weak self] in
            self?.startEscape(from: dangerSource)
        }
    }

    private func rouseAppetite(_ amount: CGFloat) {
        keenAppetite = min(1.0, keenAppetite + amount * appetite)
        searchingAppetite = max(searchingAppetite, keenAppetite)
    }

    // ─────────────────────────────────────────────
    // MARK: - Main Simulation Loop
    // ─────────────────────────────────────────────

    func update(deltaTime dt: TimeInterval,
                bounds: CGRect,
                cursorPosition: CGPoint?,
                cursorVelocity: CGPoint,
                foodPellets: [FoodPelletNode],
                allFish: [FishNode]) {
        let safeDt = CGFloat(min(max(dt, 0.001), 0.05))

        updateClocks(dt: safeDt)
        senseThreat(cursor: cursorPosition, cursorVelocity: cursorVelocity, allFish: allFish, dt: safeDt)
        senseFood(pellets: foodPellets, allFish: allFish)
        handleSplashReaction()

        updateBehavior(bounds: bounds, allFish: allFish, dt: safeDt)
        integrateHydrodynamics(dt: safeDt, bounds: bounds)
        updateSeamlessDeformableSpine(dt: safeDt)
    }

    private func updateClocks(dt: CGFloat) {
        modeTimer -= Double(dt)
        alarm *= exp(-dt / 18.0)

        if keenAppetite > 0.01 {
            keenAppetite *= exp(-dt / 25.0)
            searchingAppetite *= exp(-dt / 180.0)
            if keenAppetite < 0.01 { keenAppetite = 0 }
        }
        if appetite < 1.0 {
            appetite = min(1.0, appetite + dt * 0.02)
        }
    }

    // MARK: Looming Threat Perception
    private func senseThreat(cursor: CGPoint?, cursorVelocity: CGPoint, allFish: [FishNode], dt: CGFloat) {
        guard let c = cursor else { return }
        let toThreat = CGPoint(x: c.x - position.x, y: c.y - position.y)
        let dist = hypot(toThreat.x, toThreat.y)
        guard dist > 1 && dist < 320 else { return }

        let threatDir = CGPoint(x: toThreat.x / dist, y: toThreat.y / dist)
        let dotHead = heading.x * threatDir.x + heading.y * threatDir.y
        let isVisible = dotHead > -0.6

        let closingSpeed = -(cursorVelocity.x * threatDir.x + cursorVelocity.y * threatDir.y)
        let loomingRate = max(0, closingSpeed) / max(dist, 20.0)
        let threshold: CGFloat = (1.1 + alarm * 1.5)

        let now = CACurrentMediaTime()
        if isVisible && loomingRate > threshold && now > refractoryUntil && !mode.isEscape {
            startEscape(from: c)
            spreadAlarmToNeighbors(allFish: allFish, dangerSource: c)
            return
        }

        let flightZone: CGFloat = 120.0 / (1.0 + alarm)
        if dist < flightZone {
            alarm += dt * 0.05
            let shove = -(flightZone - dist) / flightZone * species.cruiseSpeed * 0.8
            swimVelocity.x += threatDir.x * shove * dt
            swimVelocity.y += threatDir.y * shove * dt
            if case .hover = mode {
                anchorPoint.x += threatDir.x * shove * dt * 0.5
                anchorPoint.y += threatDir.y * shove * dt * 0.5
            }
        }
    }

    private func spreadAlarmToNeighbors(allFish: [FishNode], dangerSource: CGPoint) {
        for other in allFish where other !== self {
            let dx = other.position.x - position.x
            let dy = other.position.y - position.y
            let d = hypot(dx, dy)
            if d < 180 {
                let latency = Double(d / 180.0) * 0.10 + .random(in: 0.03...0.08)
                other.triggerContagionAlarm(from: dangerSource, latency: latency)
            }
        }
    }

    private func startEscape(from threatPos: CGPoint) {
        let now = CACurrentMediaTime()
        refractoryUntil = now + 1.5
        alarm += 1.0

        var escDir = CGPoint(x: position.x - threatPos.x, y: (position.y - threatPos.y) * 0.4).normalized
        if escDir.length < 0.1 { escDir = CGPoint(x: -heading.x, y: -heading.y) }

        let yaw0 = atan2(heading.y, heading.x)
        let targetYaw = atan2(escDir.y, escDir.x)
        var angle = targetYaw - yaw0
        while angle > .pi { angle -= .pi * 2 }
        while angle < -.pi { angle += .pi * 2 }

        currentFlick = FishFlick(
            start: now,
            yaw0: yaw0,
            angle: angle,
            curvature: 4.0 * min(1.0, 0.45 + abs(angle) / 2.0),
            thrust: 95 * species.cruiseSpeed,
            stage1: 0.055,
            stage2: 0.095,
            burst: .random(in: 0.3...0.5),
            burstThrust: 38 * species.cruiseSpeed
        )

        mode = .escape(from: threatPos)
        modeTimer = 0.65
        targetPellet = nil
        strikeUntil = 0
    }

    // MARK: Food Perception
    private func senseFood(pellets: [FoodPelletNode], allFish: [FishNode]) {
        let now = CACurrentMediaTime()
        guard !mode.isEscape, now > handlingUntil else { return }

        if let p = targetPellet {
            if p.isEaten || p.parent == nil {
                targetPellet = nil
                mode = .settle
                modeTimer = 0.8
            }
        }

        if now >= nextScanTime {
            nextScanTime = now + .random(in: 0.25...0.45)
            var bestPellet: FoodPelletNode?
            var bestDist: CGFloat = 300.0

            for p in pellets where !p.isEaten && p.parent != nil {
                let dx = p.position.x - position.x
                let dy = p.position.y - position.y
                let d = hypot(dx, dy)
                guard d < bestDist else { continue }

                let dir = CGPoint(x: dx / d, y: dy / d)
                let dot = heading.x * dir.x + heading.y * dir.y
                if dot > -0.6 {
                    bestPellet = p
                    bestDist = d
                }
            }

            if let p = bestPellet, p !== targetPellet {
                targetPellet = p
                mode = .feed(pellet: p)
                strikeAttempts = 0
                rouseAppetite(0.6)
            }
        }
    }

    private func handleSplashReaction() {
        let now = CACurrentMediaTime()
        if splashReactionTime > 0 && now >= splashReactionTime {
            splashReactionTime = 0
            if !mode.isEscape, !mode.isFeed {
                let dx = splashTargetPoint.x - position.x
                let dy = splashTargetPoint.y - position.y
                let dist = hypot(dx, dy)
                if dist > 30 {
                    startTwitch(toward: splashTargetPoint)
                    if Float.random(in: 0...1) < 0.65 {
                        mode = .travel(goal: splashTargetPoint, recruited: true)
                        modeTimer = Double(dist / species.cruiseSpeed) + 1.2
                    }
                }
            }
        }
    }

    // ─────────────────────────────────────────────
    // MARK: - Behavior State Execution
    // ─────────────────────────────────────────────

    private func updateBehavior(bounds: CGRect, allFish: [FishNode], dt: CGFloat) {
        let now = CACurrentMediaTime()

        // 1. Shoaling Forces
        var separation: CGPoint = .zero
        var alignment: CGPoint  = .zero
        var centroid: CGPoint   = .zero
        var neighborCount: CGFloat = 0
        var isCrowded: Bool = false

        for other in allFish where other !== self {
            let dx = other.position.x - position.x
            let dy = other.position.y - position.y
            let d = hypot(dx, dy)
            guard d < 160 else { continue }

            let dot = heading.x * (dx / d) + heading.y * (dy / d)
            guard dot > -0.6 else { continue }

            neighborCount += 1
            centroid.x += other.position.x
            centroid.y += other.position.y
            alignment.x += other.swimVelocity.x
            alignment.y += other.swimVelocity.y

            let spacing = bodyLength * 1.6
            if d < spacing {
                separation.x -= (dx / d) * ((spacing - d) / spacing)
                separation.y -= (dy / d) * ((spacing - d) / spacing)
                if d < bodyLength * 0.65 { isCrowded = true }
            }
        }

        if neighborCount > 0 {
            centroid.x = (centroid.x / neighborCount) - position.x
            centroid.y = (centroid.y / neighborCount) - position.y
            alignment.x /= neighborCount
            alignment.y /= neighborCount
        }

        if isCrowded && currentFlick == nil && now > lastFlickTime + 0.6 {
            startTwitch(toward: CGPoint(x: position.x + separation.x, y: position.y + separation.y))
        }

        // 2. Behavioral Desires
        var desiredSteer: CGPoint = .zero

        switch mode {
        case .hover:
            pectoralBrake = 0.35
            let dx = anchorPoint.x - position.x
            let dy = anchorPoint.y - position.y
            desiredSteer.x += dx * 0.35
            desiredSteer.y += dy * 0.35

            if neighborCount > 0 {
                desiredSteer.x += alignment.x * 0.25 * (1.0 - keenAppetite)
                desiredSteer.y += alignment.y * 0.25 * (1.0 - keenAppetite)
            }

            if now >= nextTwitchTime && currentFlick == nil {
                nextTwitchTime = now + .random(in: 4.0...8.0)
                startTwitch(toward: nil)
            }

            if now >= nextExcursionTime || modeTimer <= 0 {
                let nextGoal = pickExcursionDestination(bounds: bounds)
                mode = .travel(goal: nextGoal, recruited: false)
                modeTimer = Double(hypot(nextGoal.x - position.x, nextGoal.y - position.y) / species.cruiseSpeed) + 2.5
            }

        case .travel(let goal, _):
            pectoralBrake = 0.05
            let dx = goal.x - position.x
            let dy = goal.y - position.y
            let dist = hypot(dx, dy)

            if dist < 45 || modeTimer <= 0 {
                mode = .settle
                modeTimer = .random(in: 0.8...1.6)
            } else {
                let speed = species.cruiseSpeed * character * (1.0 + keenAppetite * 0.4)
                desiredSteer.x += (dx / dist) * speed
                desiredSteer.y += (dy / dist) * speed
            }

            if neighborCount > 0 {
                desiredSteer.x += alignment.x * 0.35 * (1.0 - keenAppetite)
                desiredSteer.y += alignment.y * 0.35 * (1.0 - keenAppetite)
                let cDist = hypot(centroid.x, centroid.y)
                if cDist > 85 {
                    desiredSteer.x += (centroid.x / cDist) * species.cruiseSpeed * 0.25
                    desiredSteer.y += (centroid.y / cDist) * species.cruiseSpeed * 0.25
                }
            }

        case .inspect(let pt):
            pectoralBrake = 0.65
            let dx = pt.x - position.x, dy = pt.y - position.y
            let dist = hypot(dx, dy)
            if dist > 15 {
                desiredSteer.x += (dx / dist) * 15
                desiredSteer.y += (dy / dist) * 15
            }
            if modeTimer <= 0 {
                mode = .settle; modeTimer = 1.0
            }

        case .settle:
            pectoralBrake = 0.85
            desiredSteer = .zero
            if modeTimer <= 0 {
                anchorPoint = position
                mode = .hover
                nextTwitchTime = now + .random(in: 1.0...4.0)
                nextExcursionTime = now + .random(in: 3.0...8.0)
            }

        case .feed(let pellet):
            if pellet.isEaten || pellet.parent == nil {
                targetPellet = nil
                mode = .settle
                modeTimer = 0.5
                break
            }

            let snoutX = spineJoints.first?.position.x ?? position.x
            let snoutY = spineJoints.first?.position.y ?? position.y
            let toPelletX = pellet.position.x - (position.x + snoutX)
            let toPelletY = pellet.position.y - (position.y + snoutY)
            let pelletDist = hypot(toPelletX, toPelletY)

            let brakeRange = bodyLength * 1.8
            let stalkRange = bodyLength * 0.65

            if strikeUntil > 0 {
                if pelletDist <= 12.0 {
                    pellet.eat()
                    parent?.addChild(ParticleEffects.eatSparkle(at: pellet.position))
                    rouseAppetite(0.5)
                    appetite = max(0.15, appetite - 0.12)
                    handlingUntil = now + .random(in: 0.4...0.8)
                    targetPellet = nil
                    strikeUntil = 0
                    mode = .settle
                    modeTimer = 1.2
                } else if now >= strikeUntil {
                    strikeUntil = 0
                    strikeAttempts += 1
                    handlingUntil = now + 0.25
                    if strikeAttempts >= 3 {
                        targetPellet = nil
                        mode = .settle
                        modeTimer = 1.0
                    }
                }
            } else if now >= handlingUntil && currentFlick == nil && pelletDist <= stalkRange {
                let currentYaw = atan2(heading.y, heading.x)
                let angle = atan2(toPelletY, toPelletX) - currentYaw
                currentFlick = FishFlick(
                    start: now,
                    yaw0: currentYaw,
                    angle: angle,
                    curvature: 2.8,
                    thrust: 70 * species.cruiseSpeed,
                    stage1: 0.045,
                    stage2: 0.065,
                    burst: 0.06,
                    burstThrust: 22 * species.cruiseSpeed
                )
                strikeUntil = now + 0.045 + 0.065 + 0.06
            } else {
                if pelletDist < brakeRange {
                    pectoralBrake = 0.95
                    let stalkSpeed = species.cruiseSpeed * 0.35
                    desiredSteer.x = (toPelletX / max(pelletDist, 1)) * stalkSpeed
                    desiredSteer.y = (toPelletY / max(pelletDist, 1)) * stalkSpeed
                } else {
                    pectoralBrake = 0.1
                    let transitSpeed = species.maxSpeed * 0.85
                    desiredSteer.x = (toPelletX / max(pelletDist, 1)) * transitSpeed
                    desiredSteer.y = (toPelletY / max(pelletDist, 1)) * transitSpeed
                }
            }

        case .escape:
            pectoralBrake = 0.0
            if modeTimer <= 0 && currentFlick == nil {
                mode = .settle
                modeTimer = 1.0
            }
        }

        // Boundary Soft Repulsion
        let margin: CGFloat = bodyLength * 1.3
        if position.x < bounds.minX + margin { desiredSteer.x += (bounds.minX + margin - position.x) * 2.8 }
        if position.x > bounds.maxX - margin { desiredSteer.x -= (position.x - bounds.maxX + margin) * 2.8 }
        if position.y < bounds.minY + margin { desiredSteer.y += (bounds.minY + margin - position.y) * 2.8 }
        if position.y > bounds.maxY - margin { desiredSteer.y -= (position.y - bounds.maxY + margin) * 2.8 }

        desiredSteer.x += separation.x * species.cruiseSpeed * 0.6
        desiredSteer.y += separation.y * species.cruiseSpeed * 0.6

        applyPropulsion(desiredSteer: desiredSteer, dt: dt, now: now)
    }

    private func startTwitch(toward pt: CGPoint?) {
        let now = CACurrentMediaTime()
        let currentYaw = atan2(heading.y, heading.x)
        let targetYaw: CGFloat
        if let p = pt {
            targetYaw = atan2(p.y - position.y, p.x - position.x)
        } else {
            targetYaw = currentYaw + .random(in: -0.65...0.65)
        }

        var angle = targetYaw - currentYaw
        while angle > .pi { angle -= .pi * 2 }
        while angle < -.pi { angle += .pi * 2 }

        currentFlick = FishFlick(
            start: now,
            yaw0: currentYaw,
            angle: angle,
            curvature: 2.0 * min(1.0, 0.3 + abs(angle)),
            thrust: 14 * species.cruiseSpeed,
            stage1: 0.15,
            stage2: 0.20,
            burst: 0,
            burstThrust: 0
        )
        lastFlickTime = now
    }

    private func pickExcursionDestination(bounds: CGRect) -> CGPoint {
        if searchingAppetite > 0.2 && Float.random(in: 0...1) < 0.6 {
            return CGPoint(
                x: .random(in: bounds.minX + 50 ... bounds.maxX - 50),
                y: bounds.minY + .random(in: 12...45)
            )
        }
        return CGPoint(
            x: .random(in: bounds.minX + 40 ... bounds.maxX - 40),
            y: .random(in: bounds.minY + 30 ... bounds.maxY - 30)
        )
    }

    // ─────────────────────────────────────────────
    // MARK: - Hydrodynamics & Propulsion
    // ─────────────────────────────────────────────

    private func applyPropulsion(desiredSteer: CGPoint, dt: CGFloat, now: TimeInterval) {
        if let flick = currentFlick {
            let t = now - flick.start
            if t < flick.stage1 {
                let k = CGFloat(t / flick.stage1)
                let smoothK = k * k * (3.0 - 2.0 * k)
                let yaw = flick.yaw0 + flick.angle * smoothK
                heading = CGPoint(x: cos(yaw), y: sin(yaw))
                bodyBend = flick.curvature * sin(k * .pi * 0.5) * (flick.angle >= 0 ? 1 : -1)
                bodyEffort = 0
            } else if t < flick.stage1 + flick.stage2 {
                let k = CGFloat((t - flick.stage1) / flick.stage2)
                let yaw = flick.yaw0 + flick.angle
                heading = CGPoint(x: cos(yaw), y: sin(yaw))
                bodyBend = flick.curvature * (1.0 - 1.5 * k) * (flick.angle >= 0 ? 1 : -1)
                let thrust = flick.thrust * sin(k * .pi)
                swimVelocity.x += heading.x * thrust * dt
                swimVelocity.y += heading.y * thrust * dt
                bodyEffort = 1.0
            } else if t < flick.stage1 + flick.stage2 + flick.burst {
                let k = CGFloat((t - flick.stage1 - flick.stage2) / flick.burst)
                let thrust = flick.burstThrust * (1.0 - k)
                swimVelocity.x += heading.x * thrust * dt
                swimVelocity.y += heading.y * thrust * dt
                bodyEffort = 1.0 - k
            } else {
                currentFlick = nil
            }
            return
        }

        // Smooth Heading Turn & Pitch
        let steerMag = hypot(desiredSteer.x, desiredSteer.y)
        if steerMag > 5 {
            let targetYaw = atan2(desiredSteer.y, desiredSteer.x)
            let currentYaw = atan2(heading.y, heading.x)
            var error = targetYaw - currentYaw
            while error > .pi { error -= .pi * 2 }
            while error < -.pi { error += .pi * 2 }

            let turnRate: CGFloat = (mode.isEscape ? 8.0 : (mode.isFeed ? 4.5 : 2.6))
            let dYaw = max(-turnRate, min(turnRate, error * 3.2)) * dt
            let newYaw = currentYaw + dYaw
            heading = CGPoint(x: cos(newYaw), y: sin(newYaw))

            let speed = max(15.0, hypot(swimVelocity.x, swimVelocity.y))
            let targetBend = max(-2.4, min(2.4, (dYaw / dt) / speed * 28.0))
            bodyBend += (targetBend - bodyBend) * min(1.0, dt * 6.0)
        } else {
            bodyBend *= exp(-dt * 4.0)
        }

        // Intermittent Burst-and-Glide
        let forwardDemand = desiredSteer.x * heading.x + desiredSteer.y * heading.y
        let currentForward = swimVelocity.x * heading.x + swimVelocity.y * heading.y

        if let stroke = currentStroke {
            if now >= stroke.end || forwardDemand < 0 {
                currentStroke = nil
                let coastDuration: Double = (mode.isFeed ? .random(in: 0.08...0.20) : .random(in: 0.35...0.75))
                nextStrokeTime = now + coastDuration / Double(character)
            }
        }

        if currentStroke == nil && now >= nextStrokeTime && forwardDemand > 10 && currentForward < forwardDemand * 0.88 {
            let beats: Double = (forwardDemand > species.cruiseSpeed * 1.2 ? 2.0 : 1.0)
            let freq: Double = 3.2 * Double(character)
            currentStroke = FishStroke(
                start: now,
                end: now + beats / freq,
                thrust: min(species.maxSpeed * 3.5, forwardDemand * 2.6)
            )
        }

        var propulsiveThrust: CGFloat = 0
        if let stroke = currentStroke {
            let progress = CGFloat((now - stroke.start) / max(0.01, stroke.end - stroke.start))
            let envelope = smoothstep(0, 0.22, progress) * (1.0 - smoothstep(0.70, 1.0, progress))
            propulsiveThrust = stroke.thrust * envelope
            bodyEffort += (envelope - bodyEffort) * min(1.0, dt * 12.0)
        } else {
            bodyEffort *= exp(-dt * 10.0)
        }

        swimVelocity.x += heading.x * propulsiveThrust * dt
        swimVelocity.y += heading.y * propulsiveThrust * dt

        // High cross-flow drag
        let forwardVel = swimVelocity.x * heading.x + swimVelocity.y * heading.y
        let lateralVelX = swimVelocity.x - heading.x * forwardVel
        let lateralVelY = swimVelocity.y - heading.y * forwardVel
        swimVelocity.x -= lateralVelX * (1.0 - exp(-dt * 4.5))
        swimVelocity.y -= lateralVelY * (1.0 - exp(-dt * 4.5))

        // Axial drag
        let speed = hypot(swimVelocity.x, swimVelocity.y)
        let drag = (0.35 * speed + 0.008 * speed * speed) * dt
        let dragFactor = max(0.0, 1.0 - drag)
        swimVelocity.x *= dragFactor
        swimVelocity.y *= dragFactor
    }

    private func integrateHydrodynamics(dt: CGFloat, bounds: CGRect) {
        position.x += swimVelocity.x * dt
        position.y += swimVelocity.y * dt

        position.x = max(bounds.minX, min(bounds.maxX, position.x))
        position.y = max(bounds.minY, min(bounds.maxY, position.y))
    }

    // ─────────────────────────────────────────────
    // MARK: - Fluid Seamless Deformable Spine Rendering
    // ─────────────────────────────────────────────

    private func updateSeamlessDeformableSpine(dt: CGFloat) {
        let freq: CGFloat = (mode.isEscape ? 6.5 : 3.2 * character)
        if currentStroke != nil || currentFlick != nil {
            swimPhase = (swimPhase + dt * .pi * 2 * freq).truncatingRemainder(dividingBy: .pi * 2)
        }
        finPhase = (finPhase + dt * .pi * 2 * (2.4 + bodyEffort * 1.8)).truncatingRemainder(dividingBy: .pi * 2)
        breathPhase = (breathPhase + dt * .pi * 2 * 1.2).truncatingRemainder(dividingBy: .pi * 2)

        let rawYaw = atan2(heading.y, heading.x)
        let facingLeft = cos(rawYaw) < 0

        // Always keep dorsal (top) part of fish strictly on top
        self.xScale = facingLeft ? -1.0 : 1.0
        self.yScale = 1.0

        // Natural vertical swim pitch (clamped to +/- 45 degrees so top remains comfortably upright)
        let naturalPitch: CGFloat
        if facingLeft {
            let pitchDiff = rawYaw >= 0 ? (rawYaw - .pi) : (rawYaw + .pi)
            naturalPitch = pitchDiff
        } else {
            naturalPitch = rawYaw
        }
        let clampedPitch = max(-.pi * 0.25, min(.pi * 0.25, naturalPitch))
        self.zRotation = clampedPitch

        // 1. Calculate continuous deformed spine positions & tangents
        let waveAmp = 0.85 * bodyEffort
        for i in 0..<spineJointCount {
            let s = CGFloat(i) / CGFloat(spineJointCount - 1)
            let baseX = bodyLength * (0.45 - s)

            // Traveling wave lateral displacement (carangiform: builds toward tail)
            let waveOffset = waveAmp * pow(s, 1.35) * sin(swimPhase - s * 4.8) * (bodyHeight * 0.35)
            // Head slight counter-yaw
            let headCounter = (s < 0.2) ? (-0.05 * bodyEffort * sin(swimPhase) * bodyHeight) : 0
            // Turning curvature bend
            let bendOffset = bodyBend * pow(s, 1.25) * (bodyHeight * 0.40)

            let localY = waveOffset + headCounter - bendOffset
            spineJoints[i].position = CGPoint(x: baseX, y: localY)
            spineJoints[i].halfHeight = calculateBodyHalfHeight(at: s)
        }

        // Compute local joint tangent angles
        for i in 0..<spineJointCount {
            if i == 0 {
                let dx = spineJoints[1].position.x - spineJoints[0].position.x
                let dy = spineJoints[1].position.y - spineJoints[0].position.y
                spineJoints[0].angle = atan2(dy, dx)
            } else if i == spineJointCount - 1 {
                let dx = spineJoints[i].position.x - spineJoints[i - 1].position.x
                let dy = spineJoints[i].position.y - spineJoints[i - 1].position.y
                spineJoints[i].angle = atan2(dy, dx)
            } else {
                let dx = spineJoints[i + 1].position.x - spineJoints[i - 1].position.x
                let dy = spineJoints[i + 1].position.y - spineJoints[i - 1].position.y
                spineJoints[i].angle = atan2(dy, dx)
            }
        }

        // 2. Build Smooth Continuous Body Spline
        let bodyPath = CGMutablePath()
        // Tangent points left (angle ~pi), so dorsal (+y, UP) normal is (sin theta, -cos theta)
        let topPoints: [CGPoint] = spineJoints.map { j in
            let nx = sin(j.angle), ny = -cos(j.angle)
            return CGPoint(x: j.position.x + nx * j.halfHeight, y: j.position.y + ny * j.halfHeight)
        }
        // Ventral (-y, DOWN) normal is (-sin theta, cos theta)
        let botPoints: [CGPoint] = spineJoints.map { j in
            let nx = -sin(j.angle), ny = cos(j.angle)
            return CGPoint(x: j.position.x + nx * j.halfHeight, y: j.position.y + ny * j.halfHeight)
        }

        // Snout
        bodyPath.move(to: spineJoints[0].position)
        // Top dorsal edge
        for i in 0..<topPoints.count - 1 {
            let mid = CGPoint(x: (topPoints[i].x + topPoints[i + 1].x) * 0.5,
                              y: (topPoints[i].y + topPoints[i + 1].y) * 0.5)
            bodyPath.addQuadCurve(to: mid, control: topPoints[i])
        }
        bodyPath.addLine(to: topPoints.last!)

        // Peduncle base end
        bodyPath.addLine(to: botPoints.last!)

        // Bottom ventral edge (reverse)
        for i in stride(from: botPoints.count - 1, to: 0, by: -1) {
            let mid = CGPoint(x: (botPoints[i].x + botPoints[i - 1].x) * 0.5,
                              y: (botPoints[i].y + botPoints[i - 1].y) * 0.5)
            bodyPath.addQuadCurve(to: mid, control: botPoints[i])
        }
        bodyPath.addLine(to: spineJoints[0].position)
        bodyPath.closeSubpath()

        bodyShapeNode.path = bodyPath

        // 3. Specular Flank Highlight (upper dorsal glow)
        let shinePath = CGMutablePath()
        if topPoints.count >= 7 {
            shinePath.move(to: CGPoint(x: topPoints[1].x, y: topPoints[1].y - 2))
            for i in 1...6 {
                shinePath.addLine(to: CGPoint(x: topPoints[i].x, y: topPoints[i].y - 2))
            }
            for i in stride(from: 6, through: 1, by: -1) {
                shinePath.addLine(to: CGPoint(x: topPoints[i].x, y: topPoints[i].y - spineJoints[i].halfHeight * 0.65))
            }
            shinePath.closeSubpath()
        }
        bodyShineNode.path = shinePath

        // 4. Caudal Fin (Tail) Flowing Mesh & Rays - Positioned accurately at peduncle base
        let tailBase = spineJoints.last!
        let tailLen = bodyLength * (species == .betta ? 0.95 : (species == .goldfish ? 0.75 : 0.55))
        let tailH   = bodyHeight * (species == .betta ? 1.35 : (species == .goldfish ? 1.15 : 0.85))

        let tailWavePhase = swimPhase - 1.2 * 4.8
        let tailSpread = sin(tailWavePhase) * 0.35 - bodyBend * 0.5
        let phi = tailBase.angle + tailSpread * 0.45

        let dirX = cos(phi), dirY = sin(phi)          // Points backwards along tail
        let normX = sin(phi), normY = -cos(phi)       // Points dorsal (+y)

        let tTop = CGPoint(
            x: tailBase.position.x + dirX * tailLen + normX * (tailH * 0.5),
            y: tailBase.position.y + dirY * tailLen + normY * (tailH * 0.5)
        )
        let tBot = CGPoint(
            x: tailBase.position.x + dirX * tailLen - normX * (tailH * 0.5),
            y: tailBase.position.y + dirY * tailLen - normY * (tailH * 0.5)
        )
        let tMid = CGPoint(
            x: tailBase.position.x + dirX * (tailLen * 0.65),
            y: tailBase.position.y + dirY * (tailLen * 0.65)
        )

        let tailPath = CGMutablePath()
        tailPath.move(to: topPoints.last!)
        let ctrlTop1 = CGPoint(x: topPoints.last!.x + dirX * (tailLen * 0.35) + normX * (tailH * 0.30),
                               y: topPoints.last!.y + dirY * (tailLen * 0.35) + normY * (tailH * 0.30))
        let ctrlTop2 = CGPoint(x: tTop.x - dirX * (tailLen * 0.25) + normX * (tailH * 0.1),
                               y: tTop.y - dirY * (tailLen * 0.25) + normY * (tailH * 0.1))
        tailPath.addCurve(to: tTop, control1: ctrlTop1, control2: ctrlTop2)

        let ctrlCleftTop = CGPoint(x: (tTop.x + tMid.x) * 0.5 + normX * (tailH * 0.08),
                                   y: (tTop.y + tMid.y) * 0.5 + normY * (tailH * 0.08))
        tailPath.addQuadCurve(to: tMid, control: ctrlCleftTop)

        let ctrlCleftBot = CGPoint(x: (tBot.x + tMid.x) * 0.5 - normX * (tailH * 0.08),
                                   y: (tBot.y + tMid.y) * 0.5 - normY * (tailH * 0.08))
        tailPath.addQuadCurve(to: tBot, control: ctrlCleftBot)

        let ctrlBot1 = CGPoint(x: tBot.x - dirX * (tailLen * 0.25) - normX * (tailH * 0.1),
                               y: tBot.y - dirY * (tailLen * 0.25) - normY * (tailH * 0.1))
        let ctrlBot2 = CGPoint(x: botPoints.last!.x + dirX * (tailLen * 0.35) - normX * (tailH * 0.30),
                               y: botPoints.last!.y + dirY * (tailLen * 0.35) - normY * (tailH * 0.30))
        tailPath.addCurve(to: botPoints.last!, control1: ctrlBot1, control2: ctrlBot2)
        tailPath.addLine(to: topPoints.last!)
        tailPath.closeSubpath()
        caudalFinNode.path = tailPath

        // Caudal Fin Rays
        let raysPath = CGMutablePath()
        for i in -4...4 {
            let tf = CGFloat(i) / 4.0
            let targetPt: CGPoint
            if tf >= 0 {
                targetPt = CGPoint(
                    x: tMid.x + (tTop.x - tMid.x) * tf,
                    y: tMid.y + (tTop.y - tMid.y) * tf
                )
            } else {
                targetPt = CGPoint(
                    x: tMid.x + (tBot.x - tMid.x) * (-tf),
                    y: tMid.y + (tBot.y - tMid.y) * (-tf)
                )
            }
            raysPath.move(to: tailBase.position)
            raysPath.addLine(to: targetPt)
        }
        caudalRaysNode.path = raysPath

        // 5. Dorsal Fin (on dorsal edge)
        if spineJoints.count >= 7 {
            let dStart = topPoints[2]
            let dEnd   = topPoints[6]
            let midJ   = spineJoints[4]
            let dNormX = sin(midJ.angle), dNormY = -cos(midJ.angle)
            let finH = bodyHeight * (species == .angelfish ? 0.75 : (species == .betta ? 0.58 : 0.42))
            let dorsalPath = CGMutablePath()
            dorsalPath.move(to: dStart)
            dorsalPath.addCurve(to: dEnd,
                                control1: CGPoint(x: dStart.x + dNormX * finH, y: dStart.y + dNormY * finH),
                                control2: CGPoint(x: dEnd.x + dNormX * (finH * 0.7), y: dEnd.y + dNormY * (finH * 0.7)))
            dorsalPath.addLine(to: dEnd)
            dorsalPath.closeSubpath()
            dorsalFinNode.path = dorsalPath
        }

        // 6. Pelvic Fin (on ventral edge)
        if spineJoints.count >= 6 {
            let pStart = botPoints[3]
            let pEnd   = botPoints[5]
            let midJ   = spineJoints[4]
            let pNormX = -sin(midJ.angle), pNormY = cos(midJ.angle)
            let finH   = bodyHeight * 0.28
            let pelvicPath = CGMutablePath()
            pelvicPath.move(to: pStart)
            pelvicPath.addQuadCurve(to: pEnd, control: CGPoint(x: (pStart.x + pEnd.x) * 0.5 + pNormX * finH,
                                                               y: (pStart.y + pEnd.y) * 0.5 + pNormY * finH))
            pelvicPath.closeSubpath()
            pelvicFinNode.path = pelvicPath
        }

        // 7. Dynamic Species Patterns Rendering
        updateSpeciesPatterns(topPoints: topPoints, botPoints: botPoints)

        // 8. Eye & Gill Placement
        if spineJoints.count >= 3 {
            let headJ = spineJoints[1]
            let eyeNormX = sin(headJ.angle), eyeNormY = -cos(headJ.angle)
            eyeContainer.position = CGPoint(
                x: headJ.position.x + eyeNormX * (headJ.halfHeight * 0.35),
                y: headJ.position.y + eyeNormY * (headJ.halfHeight * 0.35)
            )

            // Gill slit
            let gillJ = spineJoints[2]
            let gillPath = CGMutablePath()
            let gTop = CGPoint(x: gillJ.position.x, y: gillJ.position.y + gillJ.halfHeight * 0.70)
            let gBot = CGPoint(x: gillJ.position.x, y: gillJ.position.y - gillJ.halfHeight * 0.70)
            gillPath.move(to: gTop)
            gillPath.addQuadCurve(to: gBot, control: CGPoint(x: gillJ.position.x + 4, y: gillJ.position.y))
            gillLineNode.path = gillPath
        }

        // 9. Pectoral Fin Flutter & Brake Flare
        let finBeat = sin(finPhase)
        let brakeFlare = pectoralBrake * 0.55
        let breathOffset = sin(breathPhase) * 0.08
        if spineJoints.count >= 3 {
            let pectJ = spineJoints[2]
            leftPectoralFin.position  = CGPoint(x: pectJ.position.x, y: pectJ.position.y - pectJ.halfHeight * 0.35)
            rightPectoralFin.position = CGPoint(x: pectJ.position.x, y: pectJ.position.y + pectJ.halfHeight * 0.35)

            leftPectoralFin.zRotation  = finBeat * 0.22 - brakeFlare - breathOffset
            rightPectoralFin.zRotation = -finBeat * 0.22 + brakeFlare + breathOffset
        }
    }

    private func updateSpeciesPatterns(topPoints: [CGPoint], botPoints: [CGPoint]) {
        let patternPath = CGMutablePath()
        guard topPoints.count >= 8 else { return }

        switch species {
        case .clownfish:
            // 3 distinctive white bands with dark edges
            for (i1, i2) in [(1, 2), (4, 5), (7, 8)] {
                patternPath.move(to: topPoints[i1])
                patternPath.addLine(to: topPoints[i2])
                patternPath.addLine(to: botPoints[i2])
                patternPath.addLine(to: botPoints[i1])
                patternPath.closeSubpath()
            }
            speciesPatternNode.fillColor   = NSColor(white: 0.98, alpha: 0.92)
            speciesPatternNode.strokeColor = NSColor.black.withAlphaComponent(0.65)
            speciesPatternNode.lineWidth   = 0.8

        case .angelfish:
            // Vertical tiger stripes
            for i in [2, 4, 6] {
                patternPath.move(to: topPoints[i])
                patternPath.addLine(to: CGPoint(x: topPoints[i].x - 2, y: topPoints[i].y))
                patternPath.addLine(to: CGPoint(x: botPoints[i].x - 2, y: botPoints[i].y))
                patternPath.addLine(to: botPoints[i])
                patternPath.closeSubpath()
            }
            speciesPatternNode.fillColor   = NSColor(red: 0.15, green: 0.15, blue: 0.18, alpha: 0.75)
            speciesPatternNode.strokeColor = .clear

        case .neonTetra:
            // Iridescent blue top stripe + vibrant red belly stripe
            patternPath.move(to: CGPoint(x: topPoints[0].x, y: topPoints[0].y - 2))
            for i in 0...7 { patternPath.addLine(to: CGPoint(x: topPoints[i].x, y: topPoints[i].y - 3)) }
            for i in stride(from: 7, through: 0, by: -1) {
                patternPath.addLine(to: CGPoint(x: topPoints[i].x, y: topPoints[i].y - spineJoints[i].halfHeight * 0.6))
            }
            patternPath.closeSubpath()
            speciesPatternNode.fillColor   = NSColor(red: 0.10, green: 0.88, blue: 1.00, alpha: 0.90)
            speciesPatternNode.strokeColor = .clear

        case .guppy, .goldfish:
            // Pearlescent spots / calico patches
            for i in [3, 5, 7] {
                let r = spineJoints[i].halfHeight * 0.55
                patternPath.addEllipse(in: CGRect(x: spineJoints[i].position.x - r,
                                                  y: spineJoints[i].position.y - r,
                                                  width: r * 2, height: r * 2))
            }
            speciesPatternNode.fillColor   = NSColor(white: 1.0, alpha: 0.45)
            speciesPatternNode.strokeColor = .clear

        case .betta:
            // Shimmer streaks along body
            for i in 2...6 {
                patternPath.move(to: CGPoint(x: topPoints[i].x - 4, y: spineJoints[i].position.y))
                patternPath.addLine(to: CGPoint(x: topPoints[i].x + 4, y: spineJoints[i].position.y + 1))
            }
            speciesPatternNode.fillColor   = .clear
            speciesPatternNode.strokeColor = NSColor(red: 0.95, green: 0.35, blue: 0.80, alpha: 0.65)
            speciesPatternNode.lineWidth   = 1.2
        }

        speciesPatternNode.path = patternPath
    }

    private func smoothstep(_ edge0: CGFloat, _ edge1: CGFloat, _ x: CGFloat) -> CGFloat {
        let t = max(0.0, min(1.0, (x - edge0) / (edge1 - edge0)))
        return t * t * (3.0 - 2.0 * t)
    }
}

// MARK: - CGPoint Extensions

private extension CGPoint {
    var length: CGFloat { hypot(x, y) }
    var normalized: CGPoint {
        let l = length
        return l > 0.0001 ? CGPoint(x: x / l, y: y / l) : CGPoint(x: 1, y: 0)
    }
}
