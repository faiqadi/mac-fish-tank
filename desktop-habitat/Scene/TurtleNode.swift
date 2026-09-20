//
//  TurtleNode.swift
//  desktop-habitat
//
//  Created by Faiqadi on 21/09/26.
//

import SpriteKit

// MARK: - Behavior State Machine

enum TurtleBehaviorMode {
    case cruise(goal: CGPoint)
    case surfaceBreathe
    case graze(point: CGPoint)
    case rest
    case feed(pellet: FoodPelletNode)
    case avoid(threat: CGPoint)
}

// MARK: - Turtle Palette

struct TurtlePalette {
    let highlight: NSColor
    let brightCyan: NSColor
    let midTeal: NSColor
    let deepTeal: NSColor
    let darkPlate: NSColor
    let plastron: NSColor
    let linework: NSColor

    static func oceanStyle(hueShift: CGFloat = 0.0) -> TurtlePalette {
        let baseR: CGFloat = 0.0
        let baseG: CGFloat = 0.90 + hueShift * 0.05
        let baseB: CGFloat = 0.95 - hueShift * 0.05

        return TurtlePalette(
            highlight: NSColor(red: min(1.0, baseR + 0.25), green: min(1.0, baseG + 0.08), blue: min(1.0, baseB + 0.05), alpha: 1.0),
            brightCyan: NSColor(red: baseR, green: baseG, blue: baseB, alpha: 1.0),
            midTeal: NSColor(red: 0.0, green: 0.52 + hueShift * 0.08, blue: 0.58 - hueShift * 0.05, alpha: 1.0),
            deepTeal: NSColor(red: 0.03, green: 0.18 + hueShift * 0.04, blue: 0.24 - hueShift * 0.02, alpha: 1.0),
            darkPlate: NSColor(red: 0.02, green: 0.07, blue: 0.10, alpha: 1.0),
            plastron: NSColor(red: 0.60, green: 0.90, blue: 0.88, alpha: 1.0),
            linework: NSColor(red: 0.01, green: 0.04, blue: 0.06, alpha: 0.95)
        )
    }
}

// MARK: - TurtleNode (3/4 Perspective Realistic Sea Turtle)

class TurtleNode: SKNode {

    // Morphology
    let shellLength: CGFloat
    let shellHeight: CGFloat
    let character: CGFloat
    let palette: TurtlePalette

    // AI & Kinematics
    private(set) var mode: TurtleBehaviorMode = .cruise(goal: .zero)
    private var modeTimer: TimeInterval = 0
    private var heading: CGPoint = CGPoint(x: 1, y: 0)
    private var velocity: CGPoint = .zero
    private var strokePhase: CGFloat = .random(in: 0 ... .pi * 2)
    private var breathTimer: TimeInterval = .random(in: 15...30)
    private var targetPellet: FoodPelletNode?
    private var nextScanTime: TimeInterval = 0
    private var isSubmerging: Bool = false
    private var flipperEffort: CGFloat = 0.5

    // Visual Rig Hierarchy
    private var rootNode: SKNode!
    private var bgFrontFlipper: SKNode!
    private var bgRearFlipper: SKNode!
    private var tailNode: SKShapeNode!
    private var plastronNode: SKShapeNode!
    private var carapaceNode: SKNode!
    private var headAndNeckNode: SKNode!
    private var fgRearFlipper: SKNode!
    private var fgFrontFlipper: SKNode!

    // MARK: - Init

    init(length: CGFloat = 72) {
        self.shellLength = length
        self.shellHeight = length * 0.52
        self.character   = .random(in: 0.88...1.12)
        let hueShift     = CGFloat.random(in: -0.06...0.06)
        self.palette     = TurtlePalette.oceanStyle(hueShift: hueShift)
        super.init()

        buildPerspectiveVisuals()
        self.zPosition = 18

        let hx: CGFloat = Bool.random() ? 1.0 : -1.0
        let hy: CGFloat = .random(in: -0.15...0.15)
        let hLen = hypot(hx, hy)
        self.heading = CGPoint(x: hx / hLen, y: hy / hLen)
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError() }

    // ─────────────────────────────────────────────
    // MARK: - 3/4 Perspective Visual Construction
    // ─────────────────────────────────────────────

    private func buildPerspectiveVisuals() {
        rootNode = SKNode()
        addChild(rootNode)

        let L = shellLength
        let H = shellHeight

        // 1. Background Rear Flipper (Z = -3)
        bgRearFlipper = buildRearFlipper(isForeground: false)
        bgRearFlipper.position  = CGPoint(x: -L * 0.35, y: H * 0.06)
        bgRearFlipper.zPosition = -3
        rootNode.addChild(bgRearFlipper)

        // 2. Background Front Flipper (Z = -2)
        bgFrontFlipper = buildForeFlipper(isForeground: false)
        bgFrontFlipper.position = CGPoint(x: L * 0.26, y: H * 0.16)
        bgFrontFlipper.zPosition = -2
        rootNode.addChild(bgFrontFlipper)

        // 3. Tail (Z = -1)
        tailNode = buildTail(L: L, H: H)
        tailNode.zPosition = -1
        rootNode.addChild(tailNode)

        // 4. Plastron (Ventral rim underside, Z = 0.5)
        plastronNode = buildPlastron(L: L, H: H)
        plastronNode.zPosition = 0.5
        rootNode.addChild(plastronNode)

        // 5. Head & Scaled Neck (Z = 1.0)
        headAndNeckNode = buildHeadAndNeck(L: L, H: H)
        headAndNeckNode.zPosition = 1.0
        rootNode.addChild(headAndNeckNode)

        // 6. Carapace (Detailed 3/4 Scutes & Radial Striations, Z = 2.0)
        carapaceNode = buildCarapace(L: L, H: H)
        carapaceNode.zPosition = 2.0
        rootNode.addChild(carapaceNode)

        // 7. Foreground Rear Flipper (Z = 3.0)
        fgRearFlipper = buildRearFlipper(isForeground: true)
        fgRearFlipper.position  = CGPoint(x: -L * 0.32, y: -H * 0.22)
        fgRearFlipper.zPosition = 3.0
        rootNode.addChild(fgRearFlipper)

        // 8. Foreground Front Flipper (Main Scaled Hydrofoil Wing, Z = 4.0)
        fgFrontFlipper = buildForeFlipper(isForeground: true)
        fgFrontFlipper.position = CGPoint(x: L * 0.20, y: -H * 0.16)
        fgFrontFlipper.zPosition = 4.0
        rootNode.addChild(fgFrontFlipper)
    }

    // ─────────────────────────────────────────────
    // MARK: - Shell (Carapace) in 3/4 Perspective
    // ─────────────────────────────────────────────

    private func buildCarapace(L: CGFloat, H: CGFloat) -> SKNode {
        let shellRoot = SKNode()

        // 1. Overall Carapace Base Dome
        let baseDomePath = CGMutablePath()
        baseDomePath.move(to: CGPoint(x: L * 0.38, y: 0.0))
        // Top dorsal curve
        baseDomePath.addCurve(to: CGPoint(x: -L * 0.46, y: -H * 0.12),
                              control1: CGPoint(x: L * 0.22, y: H * 0.72),
                              control2: CGPoint(x: -L * 0.24, y: H * 0.68))
        // Bottom marginal contour curve
        baseDomePath.addCurve(to: CGPoint(x: L * 0.38, y: 0.0),
                              control1: CGPoint(x: -L * 0.26, y: -H * 0.30),
                              control2: CGPoint(x: L * 0.16, y: -H * 0.24))
        baseDomePath.closeSubpath()

        let baseDome = SKShapeNode(path: baseDomePath)
        baseDome.fillColor   = palette.deepTeal
        baseDome.strokeColor = palette.brightCyan
        baseDome.lineWidth   = 1.5
        baseDome.zPosition   = 0.1
        shellRoot.addChild(baseDome)

        // 2. Marginal Scutes (Rim plates lining the perimeter)
        buildMarginalRim(into: shellRoot, L: L, H: H)

        // 3. Vertebral Scutes (Central dorsal ridge plates)
        buildVertebralScutes(into: shellRoot, L: L, H: H)

        // 4. Costal / Lateral Scutes with Fan Ray Striations
        buildCostalScutes(into: shellRoot, L: L, H: H)

        // 5. Dorsal Specular Ridge Luster
        let ridgePath = CGMutablePath()
        ridgePath.move(to: CGPoint(x: L * 0.28, y: H * 0.42))
        ridgePath.addCurve(to: CGPoint(x: -L * 0.35, y: H * 0.28),
                           control1: CGPoint(x: L * 0.08, y: H * 0.64),
                           control2: CGPoint(x: -L * 0.15, y: H * 0.58))
        let ridge = SKShapeNode(path: ridgePath)
        ridge.strokeColor = palette.highlight.withAlphaComponent(0.65)
        ridge.lineWidth   = 1.8
        ridge.zPosition   = 1.5
        shellRoot.addChild(ridge)

        return shellRoot
    }

    private func buildMarginalRim(into shellRoot: SKNode, L: CGFloat, H: CGFloat) {
        // Marginal scute boundary knots along lower rim
        let rimKnots: [CGPoint] = [
            CGPoint(x: L * 0.38, y: 0.0),
            CGPoint(x: L * 0.32, y: -H * 0.10),
            CGPoint(x: L * 0.22, y: -H * 0.18),
            CGPoint(x: L * 0.10, y: -H * 0.24),
            CGPoint(x: -L * 0.04, y: -H * 0.27),
            CGPoint(x: -L * 0.18, y: -H * 0.26),
            CGPoint(x: -L * 0.30, y: -H * 0.22),
            CGPoint(x: -L * 0.40, y: -H * 0.16),
            CGPoint(x: -L * 0.46, y: -H * 0.12)
        ]

        let rimInnerKnots: [CGPoint] = [
            CGPoint(x: L * 0.34, y: 0.02),
            CGPoint(x: L * 0.28, y: -H * 0.06),
            CGPoint(x: L * 0.19, y: -H * 0.12),
            CGPoint(x: L * 0.08, y: -H * 0.16),
            CGPoint(x: -L * 0.04, y: -H * 0.18),
            CGPoint(x: -L * 0.16, y: -H * 0.18),
            CGPoint(x: -L * 0.27, y: -H * 0.15),
            CGPoint(x: -L * 0.36, y: -H * 0.11),
            CGPoint(x: -L * 0.42, y: -H * 0.08)
        ]

        for i in 0 ..< (rimKnots.count - 1) {
            let p0 = rimKnots[i]
            let p1 = rimKnots[i + 1]
            let q1 = rimInnerKnots[i + 1]
            let q0 = rimInnerKnots[i]

            let mPath = CGMutablePath()
            mPath.move(to: p0)
            mPath.addLine(to: p1)
            mPath.addLine(to: q1)
            mPath.addLine(to: q0)
            mPath.closeSubpath()

            let mScute = SKShapeNode(path: mPath)
            mScute.fillColor   = (i % 2 == 0) ? palette.darkPlate : palette.deepTeal
            mScute.strokeColor = palette.brightCyan
            mScute.lineWidth   = 0.9
            mScute.zPosition   = 0.3
            shellRoot.addChild(mScute)
        }
    }

    private func buildVertebralScutes(into shellRoot: SKNode, L: CGFloat, H: CGFloat) {
        // Dorsal ridge keystone scutes
        let v1 = [
            CGPoint(x: L * 0.34, y: 0.08),
            CGPoint(x: L * 0.24, y: H * 0.42),
            CGPoint(x: L * 0.10, y: H * 0.48),
            CGPoint(x: L * 0.16, y: H * 0.14)
        ]
        let v2 = [
            CGPoint(x: L * 0.10, y: H * 0.48),
            CGPoint(x: -L * 0.08, y: H * 0.52),
            CGPoint(x: -L * 0.04, y: H * 0.16),
            CGPoint(x: L * 0.16, y: H * 0.14)
        ]
        let v3 = [
            CGPoint(x: -L * 0.08, y: H * 0.52),
            CGPoint(x: -L * 0.26, y: H * 0.45),
            CGPoint(x: -L * 0.22, y: H * 0.12),
            CGPoint(x: -L * 0.04, y: H * 0.16)
        ]
        let v4 = [
            CGPoint(x: -L * 0.26, y: H * 0.45),
            CGPoint(x: -L * 0.42, y: H * 0.12),
            CGPoint(x: -L * 0.38, y: -H * 0.02),
            CGPoint(x: -L * 0.22, y: H * 0.12)
        ]

        let vScutes = [v1, v2, v3, v4]
        for pts in vScutes {
            let path = CGMutablePath()
            path.addLines(between: pts)
            path.closeSubpath()

            let node = SKShapeNode(path: path)
            node.fillColor   = palette.darkPlate
            node.strokeColor = palette.brightCyan
            node.lineWidth   = 1.1
            node.zPosition   = 0.4
            shellRoot.addChild(node)

            // Radiating striation sunburst inside vertebral scutes
            let focus = CGPoint(
                x: (pts[0].x + pts[1].x + pts[2].x + pts[3].x) / 4.0,
                y: (pts[0].y + pts[1].y + pts[2].y + pts[3].y) / 4.0 + H * 0.04
            )
            addRadiatingStriations(into: shellRoot, points: pts, focus: focus, count: 5, z: 0.45)
        }
    }

    private func buildCostalScutes(into shellRoot: SKNode, L: CGFloat, H: CGFloat) {
        // Large Lateral/Costal Plates with prominent fan ray growth striations
        let c1 = [
            CGPoint(x: L * 0.34, y: 0.02),
            CGPoint(x: L * 0.16, y: H * 0.14),
            CGPoint(x: L * 0.12, y: -H * 0.14),
            CGPoint(x: L * 0.28, y: -H * 0.06)
        ]
        let c2 = [
            CGPoint(x: L * 0.16, y: H * 0.14),
            CGPoint(x: -L * 0.04, y: H * 0.16),
            CGPoint(x: -L * 0.06, y: -H * 0.17),
            CGPoint(x: L * 0.12, y: -H * 0.14)
        ]
        let c3 = [
            CGPoint(x: -L * 0.04, y: H * 0.16),
            CGPoint(x: -L * 0.22, y: H * 0.12),
            CGPoint(x: -L * 0.24, y: -H * 0.15),
            CGPoint(x: -L * 0.06, y: -H * 0.17)
        ]
        let c4 = [
            CGPoint(x: -L * 0.22, y: H * 0.12),
            CGPoint(x: -L * 0.38, y: -H * 0.02),
            CGPoint(x: -L * 0.38, y: -H * 0.10),
            CGPoint(x: -L * 0.24, y: -H * 0.15)
        ]

        let costals = [c1, c2, c3, c4]
        for pts in costals {
            let path = CGMutablePath()
            path.addLines(between: pts)
            path.closeSubpath()

            let node = SKShapeNode(path: path)
            node.fillColor   = palette.darkPlate
            node.strokeColor = palette.brightCyan
            node.lineWidth   = 1.2
            node.zPosition   = 0.5
            shellRoot.addChild(node)

            // Growth center apex near upper ridge of each costal scute
            let focus = CGPoint(
                x: (pts[0].x + pts[1].x) * 0.5,
                y: (pts[0].y + pts[1].y) * 0.5 - H * 0.02
            )
            addRadiatingStriations(into: shellRoot, points: pts, focus: focus, count: 8, z: 0.55)
        }
    }

    /// Adds the authentic fan-shaped growth rays radiating from scute apex outward
    private func addRadiatingStriations(into parent: SKNode, points: [CGPoint], focus: CGPoint, count: Int, z: CGFloat) {
        let raysPath = CGMutablePath()
        let b0 = points[2]
        let b1 = points[3]

        for i in 0...count {
            let t = CGFloat(i) / CGFloat(count)
            let edgePt = CGPoint(
                x: b0.x + (b1.x - b0.x) * t,
                y: b0.y + (b1.y - b0.y) * t
            )

            // Inner start offset from focus
            let startPt = CGPoint(
                x: focus.x + (edgePt.x - focus.x) * 0.22,
                y: focus.y + (edgePt.y - focus.y) * 0.22
            )
            // Fan ray tip with realistic taper
            let endPt = CGPoint(
                x: focus.x + (edgePt.x - focus.x) * 0.90,
                y: focus.y + (edgePt.y - focus.y) * 0.90
            )

            raysPath.move(to: startPt)
            raysPath.addLine(to: endPt)
        }

        let rays = SKShapeNode(path: raysPath)
        rays.strokeColor = palette.brightCyan.withAlphaComponent(0.85)
        rays.lineWidth   = 1.0
        rays.zPosition   = z
        parent.addChild(rays)
    }

    // ─────────────────────────────────────────────
    // MARK: - Plastron & Tail
    // ─────────────────────────────────────────────

    private func buildPlastron(L: CGFloat, H: CGFloat) -> SKShapeNode {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: L * 0.30, y: -H * 0.12))
        path.addCurve(to: CGPoint(x: -L * 0.32, y: -H * 0.18),
                      control1: CGPoint(x: L * 0.08, y: -H * 0.32),
                      control2: CGPoint(x: -L * 0.16, y: -H * 0.32))
        path.addLine(to: CGPoint(x: -L * 0.28, y: -H * 0.10))
        path.addLine(to: CGPoint(x: L * 0.26, y: -H * 0.04))
        path.closeSubpath()

        let plastron = SKShapeNode(path: path)
        plastron.fillColor   = palette.plastron.withAlphaComponent(0.75)
        plastron.strokeColor = palette.brightCyan.withAlphaComponent(0.6)
        plastron.lineWidth   = 0.8
        return plastron
    }

    private func buildTail(L: CGFloat, H: CGFloat) -> SKShapeNode {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -L * 0.42, y: -H * 0.08))
        path.addQuadCurve(to: CGPoint(x: -L * 0.58, y: -H * 0.18), control: CGPoint(x: -L * 0.48, y: -H * 0.12))
        path.addQuadCurve(to: CGPoint(x: -L * 0.40, y: -H * 0.22), control: CGPoint(x: -L * 0.48, y: -H * 0.20))
        path.closeSubpath()

        let tail = SKShapeNode(path: path)
        tail.fillColor   = palette.midTeal
        tail.strokeColor = palette.brightCyan
        tail.lineWidth   = 0.8
        return tail
    }

    // ─────────────────────────────────────────────
    // MARK: - Head, Neck & Mosaic Scales
    // ─────────────────────────────────────────────

    private func buildHeadAndNeck(L: CGFloat, H: CGFloat) -> SKNode {
        let root = SKNode()

        // 1. Scaled Neck Segment
        let neckPath = CGMutablePath()
        neckPath.move(to: CGPoint(x: L * 0.28, y: H * 0.10))
        neckPath.addCurve(to: CGPoint(x: L * 0.46, y: H * 0.06),
                          control1: CGPoint(x: L * 0.35, y: H * 0.16),
                          control2: CGPoint(x: L * 0.42, y: H * 0.12))
        neckPath.addLine(to: CGPoint(x: L * 0.44, y: -H * 0.16))
        neckPath.addCurve(to: CGPoint(x: L * 0.26, y: -H * 0.12),
                          control1: CGPoint(x: L * 0.38, y: -H * 0.16),
                          control2: CGPoint(x: L * 0.32, y: -H * 0.12))
        neckPath.closeSubpath()

        let neck = SKShapeNode(path: neckPath)
        neck.fillColor   = palette.midTeal
        neck.strokeColor = palette.brightCyan
        neck.lineWidth   = 0.9
        neck.zPosition   = 0.1
        root.addChild(neck)

        // 2. Neck Scale Wrinkles
        for fx in [0.32, 0.38] {
            let wx = L * CGFloat(fx)
            let wPath = CGMutablePath()
            wPath.move(to: CGPoint(x: wx, y: H * 0.10))
            wPath.addLine(to: CGPoint(x: wx + L * 0.02, y: -H * 0.12))
            let wNode = SKShapeNode(path: wPath)
            wNode.strokeColor = palette.deepTeal
            wNode.lineWidth   = 1.0
            wNode.zPosition   = 0.2
            root.addChild(wNode)
        }

        // 3. Head Rig
        let headNode = SKNode()
        headNode.position = CGPoint(x: L * 0.45, y: H * 0.02)
        headNode.name = "headNode"
        headNode.zPosition = 0.5
        root.addChild(headNode)

        let hLen = L * 0.32
        let hH   = H * 0.44

        // Head Base Contour (Curved cranial dome, hooked beak, lower throat)
        let headPath = CGMutablePath()
        headPath.move(to: .zero)
        headPath.addCurve(to: CGPoint(x: hLen * 0.94, y: 0.0),
                          control1: CGPoint(x: hLen * 0.35, y: hH * 0.50),
                          control2: CGPoint(x: hLen * 0.75, y: hH * 0.32))
        // Sharp curved beak
        headPath.addLine(to: CGPoint(x: hLen, y: -hH * 0.20))
        headPath.addQuadCurve(to: CGPoint(x: hLen * 0.82, y: -hH * 0.32), control: CGPoint(x: hLen * 0.95, y: -hH * 0.35))
        // Throat
        headPath.addCurve(to: CGPoint(x: 0, y: -hH * 0.24),
                          control1: CGPoint(x: hLen * 0.52, y: -hH * 0.38),
                          control2: CGPoint(x: hLen * 0.22, y: -hH * 0.32))
        headPath.closeSubpath()

        let headShape = SKShapeNode(path: headPath)
        headShape.fillColor   = palette.midTeal
        headShape.strokeColor = palette.brightCyan
        headShape.lineWidth   = 1.1
        headShape.zPosition   = 0.1
        headNode.addChild(headShape)

        // Jaw Split Line
        let jawPath = CGMutablePath()
        jawPath.move(to: CGPoint(x: hLen * 0.98, y: -hH * 0.15))
        jawPath.addLine(to: CGPoint(x: hLen * 0.42, y: -hH * 0.18))
        let jaw = SKShapeNode(path: jawPath)
        jaw.strokeColor = palette.darkPlate
        jaw.lineWidth   = 1.0
        jaw.zPosition   = 0.3
        headNode.addChild(jaw)

        // Mosaic Cranial Scale Scutes covering head
        buildHeadMosaicScales(into: headNode, hLen: hLen, hH: hH)

        // Realistic Eye
        let eye = buildEye(radius: hH * 0.17)
        eye.position = CGPoint(x: hLen * 0.58, y: hH * 0.10)
        eye.zPosition = 1.0
        headNode.addChild(eye)

        return root
    }

    private func buildHeadMosaicScales(into headNode: SKNode, hLen: CGFloat, hH: CGFloat) {
        // Individual polygonal scale tiles matching reference image head anatomy
        let scaleCenters: [(x: CGFloat, y: CGFloat, rx: CGFloat, ry: CGFloat)] = [
            (0.35, 0.22, 0.08, 0.07),
            (0.50, 0.25, 0.07, 0.06),
            (0.64, 0.20, 0.06, 0.05),
            (0.76, 0.12, 0.06, 0.05),
            (0.85, 0.02, 0.05, 0.04),
            (0.32, 0.08, 0.07, 0.06),
            (0.44, 0.06, 0.06, 0.05),
            (0.42, -0.06, 0.06, 0.05),
            (0.56, -0.06, 0.06, 0.05),
            (0.70, -0.04, 0.05, 0.04),
            (0.30, -0.08, 0.06, 0.05),
            (0.22, 0.04, 0.06, 0.05)
        ]

        for sc in scaleCenters {
            let cx = hLen * sc.x
            let cy = hH * sc.y
            let rx = hLen * sc.rx * 0.5
            let ry = hH * sc.ry * 0.5

            let sPath = CGMutablePath()
            sPath.addEllipse(in: CGRect(x: cx - rx, y: cy - ry, width: rx * 2, height: ry * 2))

            let tile = SKShapeNode(path: sPath)
            tile.fillColor   = palette.darkPlate
            tile.strokeColor = palette.brightCyan
            tile.lineWidth   = 0.7
            tile.zPosition   = 0.4
            headNode.addChild(tile)
        }
    }

    private func buildEye(radius r: CGFloat) -> SKNode {
        let root = SKNode()

        // Sclera
        let sclera = SKShapeNode(circleOfRadius: r)
        sclera.fillColor   = NSColor(white: 0.96, alpha: 1)
        sclera.strokeColor = palette.darkPlate
        sclera.lineWidth   = 0.8
        root.addChild(sclera)

        // Glowing Turquoise/Amber Iris
        let iris = SKShapeNode(circleOfRadius: r * 0.76)
        iris.fillColor   = palette.brightCyan
        iris.strokeColor = .clear
        root.addChild(iris)

        // Dark Pupil
        let pupil = SKShapeNode(circleOfRadius: r * 0.48)
        pupil.fillColor   = palette.darkPlate
        pupil.strokeColor = .clear
        root.addChild(pupil)

        // Specular Glint
        let glint = SKShapeNode(circleOfRadius: r * 0.22)
        glint.fillColor   = .white
        glint.strokeColor = .clear
        glint.position    = CGPoint(x: r * 0.20, y: r * 0.20)
        root.addChild(glint)

        return root
    }

    // ─────────────────────────────────────────────
    // MARK: - Fore-Flipper (Hydrofoil Wing with Mosaic Scales)
    // ─────────────────────────────────────────────

    private func buildForeFlipper(isForeground: Bool) -> SKNode {
        let flipperRoot = SKNode()
        let flen = shellLength * 0.78
        let fwid = shellHeight * 0.48

        // Hydrofoil Wing Outline
        let path = CGMutablePath()
        path.move(to: .zero)
        // Leading edge curved down and back
        path.addCurve(to: CGPoint(x: flen * 0.52, y: -fwid * 1.35),
                      control1: CGPoint(x: flen * 0.38, y: -fwid * 0.20),
                      control2: CGPoint(x: flen * 0.62, y: -fwid * 0.78))
        // Trailing tip curve back to shoulder
        path.addCurve(to: CGPoint(x: -flen * 0.16, y: -fwid * 0.46),
                      control1: CGPoint(x: flen * 0.28, y: -fwid * 1.25),
                      control2: CGPoint(x: -0.04, y: -fwid * 0.82))
        path.closeSubpath()

        let baseColor = isForeground ? palette.midTeal : palette.deepTeal
        let strokeColor = isForeground ? palette.brightCyan : palette.midTeal

        let flipperBase = SKShapeNode(path: path)
        flipperBase.fillColor   = baseColor
        flipperBase.strokeColor = strokeColor
        flipperBase.lineWidth   = 1.1
        flipperBase.zPosition   = 0.1
        flipperRoot.addChild(flipperBase)

        // Add rich mosaic polygonal scale tiles on the flipper
        if isForeground {
            buildForeFlipperMosaicScales(into: flipperRoot, flen: flen, fwid: fwid)
        }

        return flipperRoot
    }

    private func buildForeFlipperMosaicScales(into flipper: SKNode, flen: CGFloat, fwid: CGFloat) {
        // Grid of polygonal/hexagonal mosaic scale tiles across the fore-flipper blade
        let scalePositions: [(x: CGFloat, y: CGFloat, rx: CGFloat, ry: CGFloat)] = [
            // Leading edge large scales
            (0.20, -0.22, 0.09, 0.08),
            (0.32, -0.38, 0.09, 0.08),
            (0.42, -0.58, 0.09, 0.07),
            (0.48, -0.80, 0.08, 0.07),
            (0.50, -1.02, 0.07, 0.06),
            (0.46, -1.20, 0.06, 0.05),

            // Mid wing scales
            (0.08, -0.32, 0.08, 0.07),
            (0.18, -0.48, 0.08, 0.07),
            (0.28, -0.68, 0.08, 0.07),
            (0.35, -0.90, 0.07, 0.06),
            (0.38, -1.10, 0.06, 0.05),

            // Trailing edge compact scales
            (-0.02, -0.42, 0.07, 0.06),
            (0.06, -0.60, 0.07, 0.06),
            (0.14, -0.78, 0.07, 0.06),
            (0.22, -0.96, 0.06, 0.05),
            (0.26, -1.15, 0.05, 0.05)
        ]

        for sc in scalePositions {
            let cx = flen * sc.x
            let cy = fwid * sc.y
            let rx = flen * sc.rx * 0.48
            let ry = fwid * sc.ry * 0.48

            let sPath = CGMutablePath()
            // Polygonal facet
            let sides = 6
            for i in 0..<sides {
                let angle = CGFloat(i) * (.pi * 2 / CGFloat(sides)) + 0.3
                let px = cx + cos(angle) * rx
                let py = cy + sin(angle) * ry
                if i == 0 { sPath.move(to: CGPoint(x: px, y: py)) }
                else { sPath.addLine(to: CGPoint(x: px, y: py)) }
            }
            sPath.closeSubpath()

            let tile = SKShapeNode(path: sPath)
            tile.fillColor   = palette.darkPlate
            tile.strokeColor = palette.brightCyan
            tile.lineWidth   = 0.7
            tile.zPosition   = 0.3
            flipper.addChild(tile)
        }
    }

    // ─────────────────────────────────────────────
    // MARK: - Hind-Flipper (Rear Paddle with Scales)
    // ─────────────────────────────────────────────

    private func buildRearFlipper(isForeground: Bool) -> SKNode {
        let flipperRoot = SKNode()
        let flen = shellLength * 0.42
        let fwid = shellHeight * 0.32

        let path = CGMutablePath()
        path.move(to: .zero)
        path.addCurve(to: CGPoint(x: -flen * 0.95, y: -fwid * 0.65),
                      control1: CGPoint(x: -flen * 0.35, y: -fwid * 0.15),
                      control2: CGPoint(x: -flen * 0.75, y: -fwid * 0.35))
        path.addCurve(to: .zero,
                      control1: CGPoint(x: -flen * 0.65, y: -fwid * 0.85),
                      control2: CGPoint(x: -flen * 0.25, y: -fwid * 0.55))
        path.closeSubpath()

        let baseColor = isForeground ? palette.midTeal : palette.deepTeal
        let strokeColor = isForeground ? palette.brightCyan : palette.midTeal

        let flipper = SKShapeNode(path: path)
        flipper.fillColor   = baseColor
        flipper.strokeColor = strokeColor
        flipper.lineWidth   = 0.9
        flipper.zPosition   = 0.1
        flipperRoot.addChild(flipper)

        if isForeground {
            // Rear flipper scales
            let rearScales: [(x: CGFloat, y: CGFloat, r: CGFloat)] = [
                (-0.30, -0.25, 0.08),
                (-0.55, -0.40, 0.07),
                (-0.75, -0.52, 0.06),
                (-0.45, -0.52, 0.06)
            ]
            for sc in rearScales {
                let sPath = CGMutablePath()
                sPath.addEllipse(in: CGRect(
                    x: -flen * abs(sc.x) - flen * sc.r * 0.5,
                    y: -fwid * abs(sc.y) - fwid * sc.r * 0.5,
                    width: flen * sc.r,
                    height: fwid * sc.r
                ))
                let sNode = SKShapeNode(path: sPath)
                sNode.fillColor   = palette.darkPlate
                sNode.strokeColor = palette.brightCyan
                sNode.lineWidth   = 0.6
                sNode.zPosition   = 0.3
                flipperRoot.addChild(sNode)
            }
        }

        return flipperRoot
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

        updateClocks(dt: safeDt, waterSurfaceY: waterSurfaceY)
        senseThreat(cursor: cursorPosition)
        senseFood(pellets: foodPellets)

        updateBehavior(bounds: bounds, waterSurfaceY: waterSurfaceY, dt: safeDt)
        integrateMovement(dt: safeDt, bounds: bounds)
        animateLimbs(dt: safeDt)
    }

    private func updateClocks(dt: CGFloat, waterSurfaceY: CGFloat) {
        modeTimer -= Double(dt)
        breathTimer -= Double(dt)

        if breathTimer <= 0 && mode != .surfaceBreathe {
            breathTimer = .random(in: 25...45)
            mode = .surfaceBreathe
            modeTimer = 8.5
            isSubmerging = false
        }
    }

    private func senseThreat(cursor: CGPoint?) {
        guard let c = cursor else { return }
        let dx = c.x - position.x
        let dy = c.y - position.y
        let dist = hypot(dx, dy)
        if dist < 140 && mode != .avoid(threat: c) {
            mode = .avoid(threat: c)
            modeTimer = 2.2
        }
    }

    private func senseFood(pellets: [FoodPelletNode]) {
        let now = CACurrentMediaTime()
        guard now >= nextScanTime, mode != .surfaceBreathe else { return }
        nextScanTime = now + 0.5

        if let p = targetPellet {
            if p.isEaten || p.parent == nil {
                targetPellet = nil
                mode = .cruise(goal: position)
            }
        }

        var closest: FoodPelletNode?
        var minDist: CGFloat = 280.0
        for p in pellets where !p.isEaten && p.parent != nil {
            let d = hypot(p.position.x - position.x, p.position.y - position.y)
            if d < minDist {
                minDist = d
                closest = p
            }
        }

        if let p = closest, p !== targetPellet {
            targetPellet = p
            mode = .feed(pellet: p)
        }
    }

    private func updateBehavior(bounds: CGRect, waterSurfaceY: CGFloat, dt: CGFloat) {
        var desired: CGPoint = .zero
        let cruiseSpeed: CGFloat = 26.0 * character

        switch mode {
        case .cruise(let goal):
            let dx = goal.x - position.x
            let dy = goal.y - position.y
            let dist = hypot(dx, dy)
            if dist < 45 || modeTimer <= 0 {
                let next = pickNextGoal(bounds: bounds)
                mode = .cruise(goal: next)
                modeTimer = .random(in: 5...12)
            } else {
                desired = CGPoint(x: (dx / dist) * cruiseSpeed, y: (dy / dist) * cruiseSpeed)
            }
            flipperEffort = 0.5

        case .surfaceBreathe:
            if !isSubmerging {
                let targetY = waterSurfaceY - shellHeight * 0.4
                let dy = targetY - position.y
                let dx = heading.x * cruiseSpeed * 0.7
                desired = CGPoint(x: dx, y: max(0, min(cruiseSpeed * 1.3, dy * 0.9)))
                flipperEffort = 0.85

                if position.y >= targetY - 12 {
                    isSubmerging = true
                    modeTimer = 2.8
                }
            } else {
                let dx = heading.x * cruiseSpeed
                let dy = -cruiseSpeed * 0.55
                desired = CGPoint(x: dx, y: dy)
                flipperEffort = 0.35
                if modeTimer <= 0 {
                    mode = .cruise(goal: pickNextGoal(bounds: bounds))
                    modeTimer = 6.0
                }
            }

        case .graze(let pt):
            let dx = pt.x - position.x
            let dy = pt.y - position.y
            let dist = hypot(dx, dy)
            if dist > 20 {
                desired = CGPoint(x: (dx / dist) * 12.0, y: (dy / dist) * 12.0)
            }
            flipperEffort = 0.3
            if modeTimer <= 0 {
                mode = .cruise(goal: pickNextGoal(bounds: bounds))
                modeTimer = 5.0
            }

        case .rest:
            desired = .zero
            flipperEffort = 0.1
            if modeTimer <= 0 {
                mode = .cruise(goal: pickNextGoal(bounds: bounds))
                modeTimer = 6.0
            }

        case .feed(let pellet):
            if pellet.isEaten || pellet.parent == nil {
                targetPellet = nil
                mode = .cruise(goal: pickNextGoal(bounds: bounds))
                break
            }
            let dx = pellet.position.x - position.x
            let dy = pellet.position.y - position.y
            let dist = hypot(dx, dy)
            if dist <= shellLength * 0.45 {
                pellet.eat()
                parent?.addChild(ParticleEffects.eatSparkle(at: pellet.position))
                targetPellet = nil
                mode = .rest
                modeTimer = 3.0
            } else {
                desired = CGPoint(x: (dx / dist) * cruiseSpeed * 1.35, y: (dy / dist) * cruiseSpeed * 1.35)
                flipperEffort = 0.75
            }

        case .avoid(let threat):
            let dx = position.x - threat.x
            let dy = position.y - threat.y
            let dist = hypot(dx, dy)
            if dist > 0.1 {
                desired = CGPoint(x: (dx / dist) * cruiseSpeed * 1.45, y: (dy / dist) * cruiseSpeed * 1.45)
            }
            flipperEffort = 0.9
            if modeTimer <= 0 {
                mode = .cruise(goal: pickNextGoal(bounds: bounds))
                modeTimer = 4.0
            }
        }

        // Soft wall boundary repulsion
        let m = shellLength * 1.2
        if position.x < bounds.minX + m { desired.x += (bounds.minX + m - position.x) * 1.8 }
        if position.x > bounds.maxX - m { desired.x -= (position.x - bounds.maxX + m) * 1.8 }
        if position.y < bounds.minY + m { desired.y += (bounds.minY + m - position.y) * 1.8 }
        if position.y > bounds.maxY - m { desired.y -= (position.y - bounds.maxY + m) * 1.8 }

        // Smooth Heading Turn
        let steerMag = hypot(desired.x, desired.y)
        if steerMag > 2 {
            let targetYaw = atan2(desired.y, desired.x)
            let currentYaw = atan2(heading.y, heading.x)
            var error = targetYaw - currentYaw
            while error > .pi { error -= .pi * 2 }
            while error < -.pi { error += .pi * 2 }

            let dYaw = max(-1.6, min(1.6, error * 2.4)) * dt
            let newYaw = currentYaw + dYaw
            heading = CGPoint(x: cos(newYaw), y: sin(newYaw))
        }

        // Hydrodynamic Flipper Propulsion & Water Drag
        let forwardDemand = desired.x * heading.x + desired.y * heading.y
        let strokeEnvelope = max(0, sin(strokePhase))
        let thrust = forwardDemand * (0.35 + 0.65 * strokeEnvelope)

        velocity.x += heading.x * thrust * dt * 2.6
        velocity.y += heading.y * thrust * dt * 2.6

        velocity.x *= 0.96
        velocity.y *= 0.96
    }

    private func pickNextGoal(bounds: CGRect) -> CGPoint {
        CGPoint(
            x: .random(in: bounds.minX + 70 ... bounds.maxX - 70),
            y: .random(in: bounds.minY + 50 ... bounds.maxY - 50)
        )
    }

    private func integrateMovement(dt: CGFloat, bounds: CGRect) {
        position.x += velocity.x * dt
        position.y += velocity.y * dt

        position.x = max(bounds.minX, min(bounds.maxX, position.x))
        position.y = max(bounds.minY, min(bounds.maxY, position.y))
    }

    // ─────────────────────────────────────────────
    // MARK: - Flipper & Limb Animations
    // ─────────────────────────────────────────────

    private func animateLimbs(dt: CGFloat) {
        let speed = hypot(velocity.x, velocity.y)
        let strokeRate = (1.0 + speed * 0.03 + flipperEffort * 0.5) * character
        strokePhase = (strokePhase + dt * .pi * 2 * strokeRate).truncatingRemainder(dividingBy: .pi * 2)

        let rawYaw = atan2(heading.y, heading.x)
        let facingLeft = cos(rawYaw) < 0

        // Always keep dorsal carapace strictly on top
        rootNode.xScale = facingLeft ? -1.0 : 1.0
        rootNode.yScale = 1.0

        let naturalPitch: CGFloat
        if facingLeft {
            let pitchDiff = rawYaw >= 0 ? (rawYaw - .pi) : (rawYaw + .pi)
            naturalPitch = pitchDiff
        } else {
            naturalPitch = rawYaw
        }
        let clampedPitch = max(-.pi * 0.20, min(.pi * 0.20, naturalPitch))
        rootNode.zRotation = clampedPitch

        // Fore-Flippers flapping & flex
        let flipperAngle = sin(strokePhase) * 0.52 * flipperEffort
        let flipperFlex  = cos(strokePhase) * 0.14

        fgFrontFlipper.zRotation = flipperAngle + 0.12
        fgFrontFlipper.yScale    = 1.0 + flipperFlex

        bgFrontFlipper.zRotation = -flipperAngle - 0.08
        bgFrontFlipper.yScale    = 0.9 - flipperFlex * 0.4

        // Hind-Flippers rudder kick
        let rearAngle = sin(strokePhase - 0.8) * 0.22
        fgRearFlipper.zRotation = rearAngle
        bgRearFlipper.zRotation = -rearAngle * 0.7

        // Head bobbing motion
        if let head = headAndNeckNode.childNode(withName: "headNode") {
            let headBob = sin(strokePhase * 0.5) * 0.05
            head.zRotation = headBob
        }
    }
}

// MARK: - Math Helpers

private func != (lhs: TurtleBehaviorMode, rhs: TurtleBehaviorMode) -> Bool {
    switch (lhs, rhs) {
    case (.surfaceBreathe, .surfaceBreathe),
         (.rest, .rest):
        return false
    default:
        return true
    }
}
