//
//  WhaleNode.swift
//  desktop-habitat
//
//  Created by Faiqadi on 21/09/26.
//

import SpriteKit

// MARK: - Whale Palette

struct WhalePalette {
    let dorsalDark: NSColor
    let dorsalMid: NSColor
    let ventralBelly: NSColor
    let pleatColor: NSColor
    let highlight: NSColor
    let eyeColor: NSColor

    static func oceanBlue() -> WhalePalette {
        WhalePalette(
            dorsalDark: NSColor(red: 0.10, green: 0.18, blue: 0.28, alpha: 0.95),
            dorsalMid: NSColor(red: 0.18, green: 0.32, blue: 0.46, alpha: 0.95),
            ventralBelly: NSColor(red: 0.72, green: 0.84, blue: 0.92, alpha: 0.90),
            pleatColor: NSColor(red: 0.12, green: 0.22, blue: 0.34, alpha: 0.85),
            highlight: NSColor(red: 0.45, green: 0.68, blue: 0.88, alpha: 0.60),
            eyeColor: NSColor(red: 0.05, green: 0.10, blue: 0.16, alpha: 1.0)
        )
    }
}

// MARK: - WhaleNode

class WhaleNode: SKNode {

    // Morphology
    let whaleLength: CGFloat
    let whaleHeight: CGFloat
    let swimmingRight: Bool
    let swimSpeed: CGFloat
    let palette: WhalePalette

    // Kinematic & Animation State
    private var swimPhase: CGFloat = 0
    private var flipperPhase: CGFloat = 0
    private var nextSpoutTime: TimeInterval = 0
    private var totalTime: TimeInterval = 0
    private(set) var isDismissed: Bool = false

    // Node Hierarchy
    private var rootNode: SKNode!
    private var bodyShapeNode: SKShapeNode!
    private var bellyShapeNode: SKShapeNode!
    private var pleatsNode: SKShapeNode!
    private var bgPectoralFlipper: SKShapeNode!
    private var fgPectoralFlipper: SKShapeNode!
    private var tailPeduncleNode: SKNode!
    private var tailFlukesNode: SKShapeNode!
    private var eyeNode: SKNode!
    private var blowholeMarker: SKNode!

    // MARK: - Init

    init(swimmingRight: Bool, length: CGFloat = 520) {
        self.swimmingRight = swimmingRight
        self.whaleLength   = length
        self.whaleHeight   = length * 0.28
        self.swimSpeed     = .random(in: 34...44)
        self.palette       = WhalePalette.oceanBlue()
        super.init()

        self.zPosition = -10 // Midground/background layer for depth
        self.nextSpoutTime = .random(in: 2.5...5.0)

        buildWhaleVisuals()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError() }

    // ─────────────────────────────────────────────
    // MARK: - Visual Construction
    // ─────────────────────────────────────────────

    private func buildWhaleVisuals() {
        rootNode = SKNode()
        addChild(rootNode)

        // Upright orientation: dorsal side strictly on top!
        rootNode.xScale = swimmingRight ? 1.0 : -1.0
        rootNode.yScale = 1.0

        let L = whaleLength
        let H = whaleHeight

        // 1. Background Pectoral Flipper (Z = -2)
        bgPectoralFlipper = buildPectoralFlipper(isForeground: false, L: L, H: H)
        bgPectoralFlipper.position  = CGPoint(x: L * 0.18, y: -H * 0.08)
        bgPectoralFlipper.zPosition = -2
        rootNode.addChild(bgPectoralFlipper)

        // 2. Tail Peduncle & Flukes Subtree (Z = 0)
        tailPeduncleNode = SKNode()
        tailPeduncleNode.position = CGPoint(x: -L * 0.28, y: 0)
        tailPeduncleNode.zPosition = 0.5
        rootNode.addChild(tailPeduncleNode)

        buildTailFlukes(into: tailPeduncleNode, L: L, H: H)

        // 3. Main Torso, Head Body & Seamless Dorsal Fin (Z = 1.0)
        buildMainBody(L: L, H: H)

        // 4. Ventral Throat Pleats / Grooves (Z = 1.2)
        buildThroatPleats(L: L, H: H)

        // 5. Eye (Z = 1.4)
        eyeNode = buildEye(radius: H * 0.045)
        eyeNode.position = CGPoint(x: L * 0.28, y: -H * 0.02)
        eyeNode.zPosition = 1.4
        rootNode.addChild(eyeNode)

        // 6. Blowhole Marker (for particle emission)
        blowholeMarker = SKNode()
        blowholeMarker.position = CGPoint(x: L * 0.22, y: H * 0.34)
        blowholeMarker.zPosition = 2.0
        rootNode.addChild(blowholeMarker)

        // 7. Foreground Pectoral Flipper (Z = 3.0)
        fgPectoralFlipper = buildPectoralFlipper(isForeground: true, L: L, H: H)
        fgPectoralFlipper.position  = CGPoint(x: L * 0.14, y: -H * 0.16)
        fgPectoralFlipper.zPosition = 3.0
        rootNode.addChild(fgPectoralFlipper)
    }

    private func buildMainBody(L: CGFloat, H: CGFloat) {
        // Dorsal & Cranial Dome Path with seamless contiguous Dorsal Fin
        let bodyPath = CGMutablePath()
        bodyPath.move(to: CGPoint(x: L * 0.44, y: -H * 0.06)) // Rostrum snout tip

        // Rostrum & blowhole rise
        bodyPath.addCurve(to: CGPoint(x: L * 0.18, y: H * 0.35),
                          control1: CGPoint(x: L * 0.38, y: H * 0.18),
                          control2: CGPoint(x: L * 0.28, y: H * 0.35))

        // Broad dorsal back sloping to anterior base of dorsal fin
        bodyPath.addCurve(to: CGPoint(x: -L * 0.08, y: H * 0.22),
                          control1: CGPoint(x: 0, y: H * 0.32),
                          control2: CGPoint(x: -L * 0.04, y: H * 0.26))

        // Dorsal Fin leading curved edge rising from dorsal back
        bodyPath.addCurve(to: CGPoint(x: -L * 0.15, y: H * 0.42),
                          control1: CGPoint(x: -L * 0.10, y: H * 0.28),
                          control2: CGPoint(x: -L * 0.13, y: H * 0.38))

        // Falcate trailing notch curving back down to dorsal spine
        bodyPath.addQuadCurve(to: CGPoint(x: -L * 0.20, y: H * 0.14),
                              control: CGPoint(x: -L * 0.16, y: H * 0.26))

        // Sloping down to caudal peduncle
        bodyPath.addCurve(to: CGPoint(x: -L * 0.30, y: H * 0.05),
                          control1: CGPoint(x: -L * 0.24, y: H * 0.10),
                          control2: CGPoint(x: -L * 0.28, y: H * 0.07))

        // Lower caudal peduncle
        bodyPath.addLine(to: CGPoint(x: -L * 0.30, y: -H * 0.08))

        // Ventral belly curve up to lower jaw
        bodyPath.addCurve(to: CGPoint(x: L * 0.22, y: -H * 0.32),
                          control1: CGPoint(x: -L * 0.12, y: -H * 0.18),
                          control2: CGPoint(x: 0, y: -H * 0.32))

        // Lower jaw arching to rostrum tip
        bodyPath.addCurve(to: CGPoint(x: L * 0.44, y: -H * 0.06),
                          control1: CGPoint(x: L * 0.34, y: -H * 0.28),
                          control2: CGPoint(x: L * 0.42, y: -H * 0.16))
        bodyPath.closeSubpath()

        bodyShapeNode = SKShapeNode(path: bodyPath)
        bodyShapeNode.fillColor   = palette.dorsalMid
        bodyShapeNode.strokeColor = palette.dorsalDark
        bodyShapeNode.lineWidth   = 2.2
        bodyShapeNode.zPosition   = 1.0
        rootNode.addChild(bodyShapeNode)

        // Dorsal Fin inner facet shading for 3D depth
        let finRidgePath = CGMutablePath()
        finRidgePath.move(to: CGPoint(x: -L * 0.15, y: H * 0.42))
        finRidgePath.addQuadCurve(to: CGPoint(x: -L * 0.19, y: H * 0.14), control: CGPoint(x: -L * 0.155, y: H * 0.26))
        finRidgePath.addLine(to: CGPoint(x: -L * 0.09, y: H * 0.22))
        finRidgePath.closeSubpath()

        let finShading = SKShapeNode(path: finRidgePath)
        finShading.fillColor   = palette.dorsalDark.withAlphaComponent(0.45)
        finShading.strokeColor = .clear
        finShading.zPosition   = 1.05
        rootNode.addChild(finShading)

        // Counter-shaded pale ventral belly overlay
        let bellyPath = CGMutablePath()
        bellyPath.move(to: CGPoint(x: L * 0.40, y: -H * 0.12))
        bellyPath.addCurve(to: CGPoint(x: L * 0.18, y: -H * 0.30),
                           control1: CGPoint(x: L * 0.32, y: -H * 0.25),
                           control2: CGPoint(x: L * 0.26, y: -H * 0.30))
        bellyPath.addCurve(to: CGPoint(x: -L * 0.20, y: -H * 0.12),
                           control1: CGPoint(x: 0, y: -H * 0.28),
                           control2: CGPoint(x: -L * 0.10, y: -H * 0.18))
        bellyPath.addLine(to: CGPoint(x: -L * 0.20, y: -H * 0.04))
        bellyPath.addCurve(to: CGPoint(x: L * 0.40, y: -H * 0.12),
                           control1: CGPoint(x: 0, y: -H * 0.08),
                           control2: CGPoint(x: L * 0.25, y: -H * 0.08))
        bellyPath.closeSubpath()

        bellyShapeNode = SKShapeNode(path: bellyPath)
        bellyShapeNode.fillColor   = palette.ventralBelly
        bellyShapeNode.strokeColor = .clear
        bellyShapeNode.zPosition   = 1.1
        rootNode.addChild(bellyShapeNode)
    }

    private func buildThroatPleats(L: CGFloat, H: CGFloat) {
        let path = CGMutablePath()
        // 5 parallel rorqual grooves along the ventral throat
        let pleatOffsets: [CGFloat] = [-0.14, -0.18, -0.22, -0.26]
        for yOff in pleatOffsets {
            let sy = H * yOff
            path.move(to: CGPoint(x: L * 0.38, y: sy + H * 0.04))
            path.addCurve(to: CGPoint(x: L * 0.02, y: sy),
                          control1: CGPoint(x: L * 0.28, y: sy - H * 0.02),
                          control2: CGPoint(x: L * 0.14, y: sy - H * 0.02))
        }

        pleatsNode = SKShapeNode(path: path)
        pleatsNode.strokeColor = palette.pleatColor
        pleatsNode.lineWidth   = 1.6
        pleatsNode.zPosition   = 1.3
        rootNode.addChild(pleatsNode)
    }

    private func buildPectoralFlipper(isForeground: Bool, L: CGFloat, H: CGFloat) -> SKShapeNode {
        let flen = L * 0.35
        let fwid = H * 0.42

        let path = CGMutablePath()
        path.move(to: .zero)
        // Swept hydrofoil leading edge
        path.addCurve(to: CGPoint(x: -flen * 0.70, y: -fwid * 1.35),
                      control1: CGPoint(x: flen * 0.05, y: -fwid * 0.45),
                      control2: CGPoint(x: -flen * 0.35, y: -fwid * 1.15))
        // Scalloped trailing tip
        path.addCurve(to: CGPoint(x: -flen * 0.40, y: -fwid * 0.20),
                      control1: CGPoint(x: -flen * 0.65, y: -fwid * 1.05),
                      control2: CGPoint(x: -flen * 0.45, y: -fwid * 0.55))
        path.closeSubpath()

        let flipper = SKShapeNode(path: path)
        let fillColor = isForeground ? palette.dorsalMid : palette.dorsalDark
        let alpha: CGFloat = isForeground ? 1.0 : 0.75
        flipper.fillColor   = fillColor.withAlphaComponent(alpha)
        flipper.strokeColor = palette.dorsalDark
        flipper.lineWidth   = 1.8
        return flipper
    }

    private func buildTailFlukes(into parent: SKNode, L: CGFloat, H: CGFloat) {
        // Tapered posterior peduncle segment
        let pedunclePath = CGMutablePath()
        pedunclePath.move(to: CGPoint(x: 0, y: H * 0.05))
        pedunclePath.addCurve(to: CGPoint(x: -L * 0.18, y: 0),
                              control1: CGPoint(x: -L * 0.08, y: H * 0.03),
                              control2: CGPoint(x: -L * 0.14, y: H * 0.01))
        pedunclePath.addCurve(to: CGPoint(x: 0, y: -H * 0.08),
                              control1: CGPoint(x: -L * 0.14, y: -H * 0.01),
                              control2: CGPoint(x: -L * 0.08, y: -H * 0.04))
        pedunclePath.closeSubpath()

        let peduncle = SKShapeNode(path: pedunclePath)
        peduncle.fillColor   = palette.dorsalMid
        peduncle.strokeColor = palette.dorsalDark
        peduncle.lineWidth   = 1.2
        parent.addChild(peduncle)

        // Broad horizontal crescent flukes
        let tLen = L * 0.14
        let tSpan = H * 0.85

        let flukesPath = CGMutablePath()
        flukesPath.move(to: CGPoint(x: -L * 0.16, y: 0))
        // Upper fluke blade
        flukesPath.addCurve(to: CGPoint(x: -L * 0.16 - tLen, y: tSpan * 0.50),
                            control1: CGPoint(x: -L * 0.16 - tLen * 0.35, y: tSpan * 0.25),
                            control2: CGPoint(x: -L * 0.16 - tLen * 0.75, y: tSpan * 0.45))
        // Upper trailing margin to central median notch
        flukesPath.addCurve(to: CGPoint(x: -L * 0.16 - tLen * 0.65, y: 0),
                            control1: CGPoint(x: -L * 0.16 - tLen * 0.95, y: tSpan * 0.25),
                            control2: CGPoint(x: -L * 0.16 - tLen * 0.75, y: tSpan * 0.08))
        // Lower trailing margin from central notch to lower fluke tip
        flukesPath.addCurve(to: CGPoint(x: -L * 0.16 - tLen, y: -tSpan * 0.50),
                            control1: CGPoint(x: -L * 0.16 - tLen * 0.75, y: -tSpan * 0.08),
                            control2: CGPoint(x: -L * 0.16 - tLen * 0.95, y: -tSpan * 0.25))
        // Lower fluke leading margin back to peduncle insertion
        flukesPath.addCurve(to: CGPoint(x: -L * 0.16, y: 0),
                            control1: CGPoint(x: -L * 0.16 - tLen * 0.75, y: -tSpan * 0.45),
                            control2: CGPoint(x: -L * 0.16 - tLen * 0.35, y: -tSpan * 0.25))
        flukesPath.closeSubpath()

        tailFlukesNode = SKShapeNode(path: flukesPath)
        tailFlukesNode.fillColor   = palette.dorsalDark
        tailFlukesNode.strokeColor = palette.dorsalMid
        tailFlukesNode.lineWidth   = 1.2
        tailFlukesNode.zPosition   = 0.3
        parent.addChild(tailFlukesNode)
    }

    private func buildEye(radius r: CGFloat) -> SKNode {
        let eye = SKNode()

        let sclera = SKShapeNode(circleOfRadius: r)
        sclera.fillColor   = NSColor(white: 0.85, alpha: 1)
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
    // MARK: - Simulation Update Loop
    // ─────────────────────────────────────────────

    func update(deltaTime dt: TimeInterval, bounds: CGRect, sceneSize: CGSize) {
        let safeDt = CGFloat(min(max(dt, 0.001), 0.05))
        totalTime += Double(safeDt)

        // 1. Move steadily across the screen
        let dir: CGFloat = swimmingRight ? 1.0 : -1.0
        position.x += dir * swimSpeed * safeDt

        // Gentle sinusoidal depth undulation
        let verticalSway = sin(totalTime * 0.8) * 0.4
        position.y += verticalSway

        // 2. Animate Cetacean Dorsoventral Undulation
        swimPhase += safeDt * 1.8
        flipperPhase += safeDt * 1.2

        let tailWave = sin(swimPhase) * 0.18
        tailPeduncleNode.zRotation = tailWave
        tailFlukesNode.yScale = 1.0 + cos(swimPhase) * 0.15

        // Pectoral flippers gentle soaring flex
        let flipperAngle = sin(flipperPhase) * 0.12
        fgPectoralFlipper.zRotation = flipperAngle - 0.08
        bgPectoralFlipper.zRotation = -flipperAngle + 0.05

        // Gentle whole-body cruising pitch
        let bodyPitch = sin(swimPhase - 0.4) * 0.05
        rootNode.zRotation = bodyPitch

        // 3. Periodic Blowhole Spout
        if totalTime >= nextSpoutTime {
            nextSpoutTime = totalTime + .random(in: 9.0...16.0)
            triggerBlowholeSpout()
        }

        // 4. Offscreen Check & Dismissal
        let margin = whaleLength * 1.5
        if swimmingRight && position.x > sceneSize.width + margin {
            isDismissed = true
        } else if !swimmingRight && position.x < -margin {
            isDismissed = true
        }
    }

    private func triggerBlowholeSpout() {
        guard let parent = self.parent else { return }
        let worldSpoutPos = convert(blowholeMarker.position, to: parent)
        let spout = ParticleEffects.whaleSpout(at: worldSpoutPos)
        parent.addChild(spout)
    }
}
