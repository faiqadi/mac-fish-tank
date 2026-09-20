//
//  DolphinNode.swift
//  desktop-habitat
//
//  Created by Faiqadi on 21/09/26.
//

import SpriteKit

// MARK: - Motivational Quotes Catalog

struct DolphinMotivations {
    static let quotes: [String] = [
        "Keep moving forward! ✨",
        "You're doing great today! 🌊",
        "Take a deep breath and smile! 🐬",
        "Small steps every day lead to big waves! 🌟",
        "Stay curious, keep swimming! 💙",
        "Believe in yourself, you've got this! 🚀",
        "Every day is a fresh tide of opportunities! ☀️",
        "Your potential is as boundless as the ocean! 🌊",
        "Celebrate your progress, no matter how small! 💫",
        "Focus on the present moment and thrive! 🌿",
        "Ride the waves of life with joy and confidence! 🐬",
        "You make the world brighter just by being you! 🌈",
        "Trust the process and enjoy the journey! ⛵️",
        "Great things take time. Keep going! 🏔️",
        "You are capable of amazing things! ⭐️",
        "Breathe in peace, exhale tension! 🫧",
        "Stay positive and ride the tide! 🏄‍♂️",
        "Every effort brings you closer to your goals! 🎯",
        "Your future is bright and full of wonders! 🌅",
        "Kindness creates the most beautiful ripples! 🌊"
    ]

    static func randomQuote() -> String {
        quotes.randomElement() ?? "Keep swimming and smiling! 🐬"
    }
}

// MARK: - Dolphin Palette

struct DolphinPalette {
    let dorsalDark: NSColor
    let dorsalMid: NSColor
    let ventralBelly: NSColor
    let beakLine: NSColor
    let eyeColor: NSColor

    static func oceanicDolphin() -> DolphinPalette {
        DolphinPalette(
            dorsalDark: NSColor(red: 0.18, green: 0.28, blue: 0.38, alpha: 1.0),
            dorsalMid: NSColor(red: 0.30, green: 0.46, blue: 0.58, alpha: 1.0),
            ventralBelly: NSColor(red: 0.88, green: 0.92, blue: 0.96, alpha: 0.95),
            beakLine: NSColor(red: 0.12, green: 0.18, blue: 0.25, alpha: 0.85),
            eyeColor: NSColor(red: 0.06, green: 0.10, blue: 0.15, alpha: 1.0)
        )
    }
}

// MARK: - Dolphin Behavior

enum DolphinBehaviorMode {
    case cruise(goal: CGPoint)
    case sprint(goal: CGPoint)
    case leap
    case curious(target: CGPoint)
}

// MARK: - DolphinNode

class DolphinNode: SKNode {

    // Morphology
    let dolphinLength: CGFloat
    let dolphinHeight: CGFloat
    let character: CGFloat
    let palette: DolphinPalette

    // AI & High-Speed Kinematics
    private var mode: DolphinBehaviorMode = .cruise(goal: .zero)
    private var modeTimer: TimeInterval = 0
    private var heading: CGPoint = CGPoint(x: 1, y: 0)
    private var velocity: CGPoint = .zero
    private var swimPhase: CGFloat = .random(in: 0 ... .pi * 2)
    private var flipperPhase: CGFloat = 0
    private var nextMotivationTimer: TimeInterval = .random(in: 10...18)
    private var activeBubbleNode: SKNode?

    // Node Rig Hierarchy
    private var rootNode: SKNode!
    private var bodyShapeNode: SKShapeNode!
    private var bellyShapeNode: SKShapeNode!
    private var bgFlipperNode: SKShapeNode!
    private var fgFlipperNode: SKShapeNode!
    private var tailPeduncleNode: SKNode!
    private var tailFlukesNode: SKShapeNode!
    private var eyeNode: SKNode!
    private var beakLineNode: SKShapeNode!

    // MARK: - Init

    init(length: CGFloat = 78) {
        self.dolphinLength = length
        self.dolphinHeight = length * 0.32
        self.character     = .random(in: 0.92...1.08)
        self.palette       = DolphinPalette.oceanicDolphin()
        super.init()

        self.zPosition = 25
        buildDolphinVisuals()

        let hx: CGFloat = Bool.random() ? 1.0 : -1.0
        let hy: CGFloat = .random(in: -0.15...0.15)
        let hLen = hypot(hx, hy)
        self.heading = CGPoint(x: hx / hLen, y: hy / hLen)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError() }

    // ─────────────────────────────────────────────
    // MARK: - Visual Construction
    // ─────────────────────────────────────────────

    private func buildDolphinVisuals() {
        rootNode = SKNode()
        addChild(rootNode)

        let L = dolphinLength
        let H = dolphinHeight

        // 1. Background Pectoral Flipper (Z = -2)
        bgFlipperNode = buildPectoralFlipper(isForeground: false, L: L, H: H)
        bgFlipperNode.position  = CGPoint(x: L * 0.16, y: -H * 0.08)
        bgFlipperNode.zPosition = -2
        rootNode.addChild(bgFlipperNode)

        // 2. Tail Peduncle & Flukes (Z = 0)
        tailPeduncleNode = SKNode()
        tailPeduncleNode.position = CGPoint(x: -L * 0.28, y: 0)
        tailPeduncleNode.zPosition = 0.5
        rootNode.addChild(tailPeduncleNode)

        buildTailFlukes(into: tailPeduncleNode, L: L, H: H)

        // 3. Main Torso with Seamless Falcate Dorsal Fin (Z = 1.0)
        buildMainBody(L: L, H: H)

        // 4. Beak / Mouth Smile Line (Z = 1.2)
        let bPath = CGMutablePath()
        bPath.move(to: CGPoint(x: L * 0.47, y: -H * 0.14))
        bPath.addQuadCurve(to: CGPoint(x: L * 0.28, y: -H * 0.12), control: CGPoint(x: L * 0.38, y: -H * 0.16))
        beakLineNode = SKShapeNode(path: bPath)
        beakLineNode.strokeColor = palette.beakLine
        beakLineNode.lineWidth   = 0.9
        beakLineNode.zPosition   = 1.2
        rootNode.addChild(beakLineNode)

        // 5. Intelligent Eye (Z = 1.4)
        eyeNode = buildEye(radius: H * 0.08)
        eyeNode.position = CGPoint(x: L * 0.28, y: H * 0.02)
        eyeNode.zPosition = 1.4
        rootNode.addChild(eyeNode)

        // 6. Foreground Pectoral Flipper (Z = 2.0)
        fgFlipperNode = buildPectoralFlipper(isForeground: true, L: L, H: H)
        fgFlipperNode.position  = CGPoint(x: L * 0.12, y: -H * 0.14)
        fgFlipperNode.zPosition = 2.0
        rootNode.addChild(fgFlipperNode)
    }

    private func buildMainBody(L: CGFloat, H: CGFloat) {
        let bodyPath = CGMutablePath()
        // Rostrum tip
        bodyPath.move(to: CGPoint(x: L * 0.48, y: -H * 0.12))
        // Rostrum bridge to melon forehead dome
        bodyPath.addCurve(to: CGPoint(x: L * 0.28, y: H * 0.32),
                          control1: CGPoint(x: L * 0.42, y: -H * 0.02),
                          control2: CGPoint(x: L * 0.36, y: H * 0.30))
        // Melon to anterior dorsal fin base
        bodyPath.addCurve(to: CGPoint(x: -L * 0.02, y: H * 0.28),
                          control1: CGPoint(x: L * 0.16, y: H * 0.34),
                          control2: CGPoint(x: L * 0.06, y: H * 0.32))
        // Falcate Curved Dorsal Fin rising high
        bodyPath.addCurve(to: CGPoint(x: -L * 0.08, y: H * 0.72),
                          control1: CGPoint(x: -L * 0.04, y: H * 0.48),
                          control2: CGPoint(x: -L * 0.06, y: H * 0.65))
        // Falcate hooked trailing edge of dorsal fin back down
        bodyPath.addQuadCurve(to: CGPoint(x: -L * 0.15, y: H * 0.20),
                              control: CGPoint(x: -L * 0.10, y: H * 0.42))
        // Dorsal slope to caudal peduncle
        bodyPath.addCurve(to: CGPoint(x: -L * 0.30, y: H * 0.06),
                          control1: CGPoint(x: -L * 0.20, y: H * 0.16),
                          control2: CGPoint(x: -L * 0.26, y: H * 0.10))
        // Caudal insertion end
        bodyPath.addLine(to: CGPoint(x: -L * 0.30, y: -H * 0.06))
        // Ventral belly curve up to lower jaw
        bodyPath.addCurve(to: CGPoint(x: L * 0.18, y: -H * 0.30),
                          control1: CGPoint(x: -L * 0.15, y: -H * 0.16),
                          control2: CGPoint(x: 0, y: -H * 0.30))
        // Lower jaw tapering to beak tip
        bodyPath.addCurve(to: CGPoint(x: L * 0.48, y: -H * 0.12),
                          control1: CGPoint(x: L * 0.32, y: -H * 0.28),
                          control2: CGPoint(x: L * 0.44, y: -H * 0.20))
        bodyPath.closeSubpath()

        bodyShapeNode = SKShapeNode(path: bodyPath)
        bodyShapeNode.fillColor   = palette.dorsalMid
        bodyShapeNode.strokeColor = palette.dorsalDark
        bodyShapeNode.lineWidth   = 1.2
        bodyShapeNode.zPosition   = 1.0
        rootNode.addChild(bodyShapeNode)

        // Pale ventral belly patch
        let bellyPath = CGMutablePath()
        bellyPath.move(to: CGPoint(x: L * 0.44, y: -H * 0.16))
        bellyPath.addCurve(to: CGPoint(x: L * 0.16, y: -H * 0.28),
                           control1: CGPoint(x: L * 0.32, y: -H * 0.26),
                           control2: CGPoint(x: L * 0.24, y: -H * 0.28))
        bellyPath.addCurve(to: CGPoint(x: -L * 0.22, y: -H * 0.10),
                           control1: CGPoint(x: 0, y: -H * 0.26),
                           control2: CGPoint(x: -L * 0.12, y: -H * 0.18))
        bellyPath.addLine(to: CGPoint(x: -L * 0.22, y: -H * 0.02))
        bellyPath.addCurve(to: CGPoint(x: L * 0.44, y: -H * 0.16),
                           control1: CGPoint(x: 0, y: -H * 0.06),
                           control2: CGPoint(x: L * 0.28, y: -H * 0.08))
        bellyPath.closeSubpath()

        bellyShapeNode = SKShapeNode(path: bellyPath)
        bellyShapeNode.fillColor   = palette.ventralBelly
        bellyShapeNode.strokeColor = .clear
        bellyShapeNode.zPosition   = 1.1
        rootNode.addChild(bellyShapeNode)
    }

    private func buildPectoralFlipper(isForeground: Bool, L: CGFloat, H: CGFloat) -> SKShapeNode {
        let flen = L * 0.26
        let fwid = H * 0.38

        let path = CGMutablePath()
        path.move(to: .zero)
        path.addCurve(to: CGPoint(x: -flen * 0.85, y: -fwid * 1.15),
                      control1: CGPoint(x: flen * 0.05, y: -fwid * 0.35),
                      control2: CGPoint(x: -flen * 0.45, y: -fwid * 0.95))
        path.addCurve(to: .zero,
                      control1: CGPoint(x: -flen * 0.65, y: -fwid * 0.65),
                      control2: CGPoint(x: -flen * 0.30, y: -fwid * 0.25))
        path.closeSubpath()

        let flipper = SKShapeNode(path: path)
        let alpha: CGFloat = isForeground ? 1.0 : 0.75
        let baseColor = isForeground ? palette.dorsalMid : palette.dorsalDark
        flipper.fillColor   = baseColor.withAlphaComponent(alpha)
        flipper.strokeColor = palette.dorsalDark
        flipper.lineWidth   = 1.0
        return flipper
    }

    private func buildTailFlukes(into parent: SKNode, L: CGFloat, H: CGFloat) {
        let pedunclePath = CGMutablePath()
        pedunclePath.move(to: CGPoint(x: 0, y: H * 0.06))
        pedunclePath.addCurve(to: CGPoint(x: -L * 0.18, y: 0),
                              control1: CGPoint(x: -L * 0.08, y: H * 0.04),
                              control2: CGPoint(x: -L * 0.14, y: H * 0.01))
        pedunclePath.addCurve(to: CGPoint(x: 0, y: -H * 0.06),
                              control1: CGPoint(x: -L * 0.14, y: -H * 0.01),
                              control2: CGPoint(x: -L * 0.08, y: -H * 0.04))
        pedunclePath.closeSubpath()

        let peduncle = SKShapeNode(path: pedunclePath)
        peduncle.fillColor   = palette.dorsalMid
        peduncle.strokeColor = palette.dorsalDark
        peduncle.lineWidth   = 1.0
        parent.addChild(peduncle)

        // Crescent Flukes
        let tLen = L * 0.12
        let tSpan = H * 0.95

        let flukesPath = CGMutablePath()
        flukesPath.move(to: CGPoint(x: -L * 0.16, y: 0))
        flukesPath.addCurve(to: CGPoint(x: -L * 0.16 - tLen, y: tSpan * 0.50),
                            control1: CGPoint(x: -L * 0.16 - tLen * 0.35, y: tSpan * 0.25),
                            control2: CGPoint(x: -L * 0.16 - tLen * 0.75, y: tSpan * 0.45))
        flukesPath.addCurve(to: CGPoint(x: -L * 0.16 - tLen * 0.60, y: 0),
                            control1: CGPoint(x: -L * 0.16 - tLen * 0.95, y: tSpan * 0.25),
                            control2: CGPoint(x: -L * 0.16 - tLen * 0.75, y: tSpan * 0.08))
        flukesPath.addCurve(to: CGPoint(x: -L * 0.16 - tLen, y: -tSpan * 0.50),
                            control1: CGPoint(x: -L * 0.16 - tLen * 0.75, y: -tSpan * 0.08),
                            control2: CGPoint(x: -L * 0.16 - tLen * 0.95, y: -tSpan * 0.25))
        flukesPath.addCurve(to: CGPoint(x: -L * 0.16, y: 0),
                            control1: CGPoint(x: -L * 0.16 - tLen * 0.75, y: -tSpan * 0.45),
                            control2: CGPoint(x: -L * 0.16 - tLen * 0.35, y: -tSpan * 0.25))
        flukesPath.closeSubpath()

        tailFlukesNode = SKShapeNode(path: flukesPath)
        tailFlukesNode.fillColor   = palette.dorsalDark
        tailFlukesNode.strokeColor = palette.dorsalMid
        tailFlukesNode.lineWidth   = 1.0
        tailFlukesNode.zPosition   = 0.3
        parent.addChild(tailFlukesNode)
    }

    private func buildEye(radius r: CGFloat) -> SKNode {
        let eye = SKNode()

        let sclera = SKShapeNode(circleOfRadius: r)
        sclera.fillColor   = NSColor(white: 0.95, alpha: 1)
        sclera.strokeColor = palette.dorsalDark
        sclera.lineWidth   = 0.5
        eye.addChild(sclera)

        let pupil = SKShapeNode(circleOfRadius: r * 0.65)
        pupil.fillColor   = palette.eyeColor
        pupil.strokeColor = .clear
        eye.addChild(pupil)

        let glint = SKShapeNode(circleOfRadius: r * 0.25)
        glint.fillColor   = .white
        glint.strokeColor = .clear
        glint.position    = CGPoint(x: r * 0.20, y: r * 0.20)
        eye.addChild(glint)

        return eye
    }

    // ─────────────────────────────────────────────
    // MARK: - Motivational Pop-up Bubble
    // ─────────────────────────────────────────────

    func popMotivationalQuote() {
        // Remove previous bubble if active
        activeBubbleNode?.removeFromParent()

        let quote = DolphinMotivations.randomQuote()

        let container = SKNode()
        container.zPosition = 100
        container.position = CGPoint(x: 0, y: dolphinHeight * 0.95)

        // Calculate text sizing
        let label = SKLabelNode(text: quote)
        label.fontName = "SFProRounded-Bold"
        label.fontSize = 12
        label.fontColor = NSColor(red: 0.05, green: 0.20, blue: 0.35, alpha: 1.0)
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center

        let textWidth = label.frame.width
        let bubbleWidth = max(textWidth + 24, 80)
        let bubbleHeight: CGFloat = 26

        // Rounded glass speech bubble background
        let bubbleRect = CGRect(x: -bubbleWidth * 0.5, y: -bubbleHeight * 0.5, width: bubbleWidth, height: bubbleHeight)
        let bubbleBg = SKShapeNode(rect: bubbleRect, cornerRadius: 13)
        bubbleBg.fillColor   = NSColor(white: 1.0, alpha: 0.92)
        bubbleBg.strokeColor = NSColor(red: 0.30, green: 0.65, blue: 0.95, alpha: 0.85)
        bubbleBg.lineWidth   = 1.5

        // Little speech pointer tail
        let tailPath = CGMutablePath()
        tailPath.move(to: CGPoint(x: -5, y: -bubbleHeight * 0.5))
        tailPath.addLine(to: CGPoint(x: 0, y: -bubbleHeight * 0.5 - 6))
        tailPath.addLine(to: CGPoint(x: 5, y: -bubbleHeight * 0.5))
        tailPath.closeSubpath()
        let tail = SKShapeNode(path: tailPath)
        tail.fillColor   = bubbleBg.fillColor
        tail.strokeColor = .clear

        container.addChild(bubbleBg)
        container.addChild(tail)
        container.addChild(label)

        // Always keep text strictly left-to-right and never mirrored or rotated
        container.xScale = 1.0
        container.yScale = 1.0
        container.zRotation = 0.0

        // Pop animation sequence: scale bounce + stay + fade out
        container.setScale(0.1)
        container.alpha = 0

        let appear = SKAction.group([
            SKAction.scale(to: 1.0, duration: 0.28).ease(.easeOut),
            SKAction.fadeIn(withDuration: 0.20)
        ])
        let gentleBob = SKAction.sequence([
            SKAction.moveBy(x: 0, y: 3, duration: 1.2),
            SKAction.moveBy(x: 0, y: -3, duration: 1.2)
        ])
        let bobForever = SKAction.repeat(gentleBob, count: 2)
        let disappear = SKAction.group([
            SKAction.scale(to: 0.3, duration: 0.25).ease(.easeIn),
            SKAction.fadeOut(withDuration: 0.25)
        ])

        let onFinished = SKAction.run { [weak self, weak container] in
            if self?.activeBubbleNode == container {
                self?.activeBubbleNode = nil
            }
        }

        container.run(SKAction.sequence([
            appear,
            bobForever,
            disappear,
            SKAction.removeFromParent(),
            onFinished
        ]))

        self.addChild(container)
        self.activeBubbleNode = container
    }

    // ─────────────────────────────────────────────
    // MARK: - Simulation Update Loop
    // ─────────────────────────────────────────────

    func update(deltaTime dt: TimeInterval,
                bounds: CGRect,
                waterSurfaceY: CGFloat,
                cursorPosition: CGPoint?,
                foodPellets: [FoodPelletNode]) {
        let safeDt = CGFloat(min(max(dt, 0.001), 0.05))

        updateMotivationClock(dt: safeDt)
        updateBehavior(bounds: bounds, waterSurfaceY: waterSurfaceY, dt: safeDt)
        integrateMovement(dt: safeDt, bounds: bounds)
        animateLimbs(dt: safeDt)
    }

    private func updateMotivationClock(dt: CGFloat) {
        nextMotivationTimer -= Double(dt)
        if nextMotivationTimer <= 0 {
            nextMotivationTimer = .random(in: 20...35)
            popMotivationalQuote()
        }

        // Guarantee speech bubble is always level and never mirrored or tilted
        if let bubble = activeBubbleNode {
            bubble.zRotation = 0.0
            if bubble.xScale < 0 { bubble.xScale = abs(bubble.xScale) }
        }
    }

    private func updateBehavior(bounds: CGRect, waterSurfaceY: CGFloat, dt: CGFloat) {
        modeTimer -= Double(dt)

        let isShowingText = (activeBubbleNode != nil)

        // Dolphin swims twice as fast as normal fish normally (~92 - 145 pt/s),
        // but slows down significantly to a peaceful, readable glide (~32 pt/s) when displaying motivational text!
        let speedMultiplier: CGFloat = isShowingText ? 0.35 : 1.0
        let baseCruiseSpeed: CGFloat = 92.0 * character * speedMultiplier
        let sprintSpeed: CGFloat     = isShowingText ? baseCruiseSpeed : (145.0 * character)
        var desired: CGPoint = .zero

        // If displaying text, override aggressive sprint or leaps with gentle cruise
        if isShowingText {
            switch mode {
            case .sprint(let goal), .curious(let goal):
                mode = .cruise(goal: goal)
            case .leap:
                mode = .cruise(goal: pickNextGoal(bounds: bounds))
                modeTimer = 6.0
            case .cruise:
                break
            }
        }

        switch mode {
        case .cruise(let goal):
            let dx = goal.x - position.x
            let dy = goal.y - position.y
            let dist = hypot(dx, dy)
            if dist < 50 || modeTimer <= 0 {
                // Pick next agile goal or transition to sprint (if not showing text)
                let next = pickNextGoal(bounds: bounds)
                if !isShowingText && Bool.random() && Bool.random() {
                    mode = .sprint(goal: next)
                    modeTimer = .random(in: 2.5...5.0)
                } else {
                    mode = .cruise(goal: next)
                    modeTimer = isShowingText ? .random(in: 6.0...10.0) : .random(in: 4.0...9.0)
                }
            } else {
                desired = CGPoint(x: (dx / dist) * baseCruiseSpeed, y: (dy / dist) * baseCruiseSpeed)
            }

        case .sprint(let goal):
            let dx = goal.x - position.x
            let dy = goal.y - position.y
            let dist = hypot(dx, dy)
            if dist < 60 || modeTimer <= 0 {
                mode = .cruise(goal: pickNextGoal(bounds: bounds))
                modeTimer = .random(in: 5...10)
            } else {
                desired = CGPoint(x: (dx / dist) * sprintSpeed, y: (dy / dist) * sprintSpeed)
            }

        case .leap:
            let targetY = waterSurfaceY - 10
            let dy = targetY - position.y
            desired = CGPoint(x: heading.x * sprintSpeed, y: dy * 1.5)
            if modeTimer <= 0 || position.y >= targetY - 15 {
                mode = .cruise(goal: pickNextGoal(bounds: bounds))
                modeTimer = 6.0
            }

        case .curious(let target):
            let dx = target.x - position.x
            let dy = target.y - position.y
            let dist = hypot(dx, dy)
            if dist > 35 {
                desired = CGPoint(x: (dx / dist) * baseCruiseSpeed * 1.1, y: (dy / dist) * baseCruiseSpeed * 1.1)
            }
            if modeTimer <= 0 {
                mode = .cruise(goal: pickNextGoal(bounds: bounds))
                modeTimer = 5.0
            }
        }

        // Soft wall boundary repulsion
        let m = dolphinLength * 1.2
        if position.x < bounds.minX + m { desired.x += (bounds.minX + m - position.x) * 2.2 }
        if position.x > bounds.maxX - m { desired.x -= (position.x - bounds.maxX + m) * 2.2 }
        if position.y < bounds.minY + m { desired.y += (bounds.minY + m - position.y) * 2.2 }
        if position.y > bounds.maxY - m { desired.y -= (position.y - bounds.maxY + m) * 2.2 }

        // Agile rapid heading turn (smoother and gentler when displaying text so text stays stable)
        let steerMag = hypot(desired.x, desired.y)
        if steerMag > 2 {
            let targetYaw = atan2(desired.y, desired.x)
            let currentYaw = atan2(heading.y, heading.x)
            var error = targetYaw - currentYaw
            while error > .pi { error -= .pi * 2 }
            while error < -.pi { error += .pi * 2 }

            let turnRateMultiplier: CGFloat = isShowingText ? 2.0 : 4.0
            let maxYawRate: CGFloat = isShowingText ? 1.8 : 3.2
            let dYaw = max(-maxYawRate, min(maxYawRate, error * turnRateMultiplier)) * dt
            let newYaw = currentYaw + dYaw
            heading = CGPoint(x: cos(newYaw), y: sin(newYaw))
        }

        // Cetacean propulsion thrust & streamlined drag
        let thrustMag = steerMag
        let thrustFactor: CGFloat = isShowingText ? 2.0 : 3.5
        velocity.x += heading.x * thrustMag * dt * thrustFactor
        velocity.y += heading.y * thrustMag * dt * thrustFactor

        let dragFactor: CGFloat = isShowingText ? 0.90 : 0.94
        velocity.x *= dragFactor
        velocity.y *= dragFactor
    }

    private func pickNextGoal(bounds: CGRect) -> CGPoint {
        CGPoint(
            x: .random(in: bounds.minX + 80 ... bounds.maxX - 80),
            y: .random(in: bounds.minY + 60 ... bounds.maxY - 50)
        )
    }

    private func integrateMovement(dt: CGFloat, bounds: CGRect) {
        position.x += velocity.x * dt
        position.y += velocity.y * dt

        position.x = max(bounds.minX, min(bounds.maxX, position.x))
        position.y = max(bounds.minY, min(bounds.maxY, position.y))
    }

    private func animateLimbs(dt: CGFloat) {
        let speed = hypot(velocity.x, velocity.y)
        let isShowingText = (activeBubbleNode != nil)
        // High fluke beat rate for fast swimming, gentle calm stroke rate when speaking
        let baseStrokeRate: CGFloat = isShowingText ? 1.1 : 2.2
        let strokeRate = (baseStrokeRate + speed * 0.022) * character
        swimPhase = (swimPhase + dt * .pi * 2 * strokeRate).truncatingRemainder(dividingBy: .pi * 2)
        flipperPhase = (flipperPhase + dt * .pi * 2 * (strokeRate * 0.6)).truncatingRemainder(dividingBy: .pi * 2)

        let rawYaw = atan2(heading.y, heading.x)
        let facingLeft = cos(rawYaw) < 0

        // Always keep dorsal side strictly on top!
        rootNode.xScale = facingLeft ? -1.0 : 1.0
        rootNode.yScale = 1.0

        let naturalPitch: CGFloat
        if facingLeft {
            let pitchDiff = rawYaw >= 0 ? (rawYaw - .pi) : (rawYaw + .pi)
            naturalPitch = pitchDiff
        } else {
            naturalPitch = rawYaw
        }
        let maxClampedAngle: CGFloat = isShowingText ? .pi * 0.12 : .pi * 0.22
        let clampedPitch = max(-maxClampedAngle, min(maxClampedAngle, naturalPitch))
        rootNode.zRotation = clampedPitch

        // Dorsoventral Fluke wave
        let flukeWave = sin(swimPhase) * (isShowingText ? 0.16 : 0.26)
        tailPeduncleNode.zRotation = flukeWave
        tailFlukesNode.yScale = 1.0 + cos(swimPhase) * (isShowingText ? 0.14 : 0.22)

        // Pectoral flipper bank flex
        let flipperAngle = sin(flipperPhase) * (isShowingText ? 0.10 : 0.18)
        fgFlipperNode.zRotation = flipperAngle
        bgFlipperNode.zRotation = -flipperAngle * 0.7
    }
}

// MARK: - Action Extension Helper

private extension SKAction {
    enum EaseMode { case easeIn, easeOut, easeInOut }
    func ease(_ mode: EaseMode) -> SKAction {
        switch mode {
        case .easeIn:
            self.timingMode = .easeIn
        case .easeOut:
            self.timingMode = .easeOut
        case .easeInOut:
            self.timingMode = .easeInEaseOut
        }
        return self
    }
}
